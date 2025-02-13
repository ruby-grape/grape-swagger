# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/string/inflections'
require 'grape-swagger/endpoint/params_parser'
require 'grape-swagger/endpoint/path_params_parser'
require 'grape-swagger/endpoint/contract_parser'
require 'grape-swagger/endpoint/header_params_parser'

module Grape
  class Endpoint # rubocop:disable Metrics/ClassLength
    REQUEST_PARAM_PARSERS = [
      GrapeSwagger::Endpoint::HeaderParamsParser,
      GrapeSwagger::Endpoint::PathParamsParser,
      GrapeSwagger::Endpoint::ContractParser,
      GrapeSwagger::Endpoint::ParamsParser
    ].freeze

    def content_types_for(target_class)
      content_types = (target_class.content_types || {}).values

      if content_types.empty?
        formats       = [target_class.format, target_class.default_format].compact.uniq
        formats       = GrapeSwagger::FORMATTER_DEFAULTS.keys if formats.empty?
        content_types = formats.filter_map { |f| GrapeSwagger::CONTENT_TYPE_DEFAULTS[f] }
      end

      content_types.uniq
    end

    # swagger spec2.0 related parts
    #
    # required keys for SwaggerObject
    def swagger_object(target_class, request, options)
      object = {
        info: info_object(options[:info].merge(version: options[:doc_version])),
        swagger: '2.0',
        produces: options[:produces] || content_types_for(target_class),
        consumes: options[:consumes],
        authorizations: options[:authorizations],
        securityDefinitions: options[:security_definitions],
        security: options[:security],
        host: GrapeSwagger::DocMethods::OptionalObject.build(:host, options, request),
        basePath: GrapeSwagger::DocMethods::OptionalObject.build(:base_path, options, request),
        schemes: options[:schemes].is_a?(String) ? [options[:schemes]] : options[:schemes]
      }

      GrapeSwagger::DocMethods::Extensions.add_extensions_to_root(options, object)
      object.delete_if { |_, value| value.blank? }
    end

    # building info object
    def info_object(infos)
      result = {
        title: infos[:title] || 'API title',
        description: infos[:description],
        termsOfService: infos[:terms_of_service_url],
        contact: contact_object(infos),
        license: license_object(infos),
        version: infos[:version]
      }

      GrapeSwagger::DocMethods::Extensions.add_extensions_to_info(infos, result)

      result.delete_if { |_, value| value.blank? }
    end

    # sub-objects of info object
    # license
    def license_object(infos)
      {
        name: infos.delete(:license),
        url: infos.delete(:license_url)
      }.delete_if { |_, value| value.blank? }
    end

    # contact
    def contact_object(infos)
      {
        name: infos.delete(:contact_name),
        email: infos.delete(:contact_email),
        url: infos.delete(:contact_url)
      }.delete_if { |_, value| value.blank? }
    end

    # building path and definitions objects
    def path_and_definition_objects(namespace_routes, options)
      @paths = {}
      @definitions = {}
      add_definitions_from options[:models]
      namespace_routes.each_value do |routes|
        path_item(routes, options)
      end

      [@paths, @definitions]
    end

    def add_definitions_from(models)
      return if models.nil?

      models.each { |x| expose_params_from_model(x) }
    end

    # path object
    def path_item(routes, options)
      routes.each do |route|
        next if hidden?(route, options)

        @item, path = GrapeSwagger::DocMethods::PathString.build(route, options)
        @entity = route.entity || route.options[:success]

        verb, method_object = method_object(route, options, path)

        if @paths.key?(path.to_s)
          @paths[path.to_s][verb] = method_object
        else
          @paths[path.to_s] = { verb => method_object }
        end

        GrapeSwagger::DocMethods::Extensions.add(@paths[path.to_s], @definitions, route)
      end
    end

    def method_object(route, options, path)
      method = {}
      method[:summary]     = summary_object(route)
      method[:description] = description_object(route)
      method[:produces]    = produces_object(route, options[:produces] || options[:format])
      method[:consumes]    = consumes_object(route, options[:consumes] || options[:format])
      method[:parameters]  = params_object(route, options, path, method[:consumes])
      method[:security]    = security_object(route)
      method[:responses]   = response_object(route, options)
      method[:tags]        = route.options.fetch(:tags, tag_object(route, path))
      method[:operationId] = GrapeSwagger::DocMethods::OperationId.build(route, path)
      method[:deprecated] = deprecated_object(route)
      method.delete_if { |_, value| value.nil? }

      [route.request_method.downcase.to_sym, method]
    end

    def deprecated_object(route)
      route.options[:deprecated] if route.options.key?(:deprecated)
    end

    def security_object(route)
      route.options[:security] if route.options.key?(:security)
    end

    def summary_object(route)
      summary = route.options[:desc] if route.options.key?(:desc)
      summary = route.description if route.description.present? && route.options.key?(:detail)
      summary = route.options[:summary] if route.options.key?(:summary)

      summary
    end

    def description_object(route)
      description = route.description if route.description.present?
      description = route.options[:detail] if route.options.key?(:detail)

      description
    end

    def produces_object(route, format)
      return ['application/octet-stream'] if file_response?(route.attributes.success) &&
                                             !route.attributes.produces.present?

      mime_types = GrapeSwagger::DocMethods::ProducesConsumes.call(format)

      route_mime_types = %i[formats content_types produces].map do |producer|
        possible = route.options[producer]
        GrapeSwagger::DocMethods::ProducesConsumes.call(possible) if possible.present?
      end.flatten.compact.uniq

      route_mime_types.present? ? route_mime_types : mime_types
    end

    SUPPORTS_CONSUMES = %i[post put patch].freeze

    def consumes_object(route, format)
      return unless SUPPORTS_CONSUMES.include?(route.request_method.downcase.to_sym)

      GrapeSwagger::DocMethods::ProducesConsumes.call(route.settings.dig(:description, :consumes) || format)
    end

    def params_object(route, options, path, consumes)
      parameters = build_request_params(route, options).each_with_object([]) do |(param, value), memo|
        next if hidden_parameter?(value)

        value = { required: false }.merge(value) if value.is_a?(Hash)
        _, value = default_type([[param, value]]).first if value == ''

        if value.dig(:documentation, :type)
          expose_params(value[:documentation][:type])
        elsif value[:type]
          expose_params(value[:type])
        end
        memo << GrapeSwagger::DocMethods::ParseParams.call(param, value, path, route, @definitions, consumes)
      end

      if GrapeSwagger::DocMethods::MoveParams.can_be_moved?(route.request_method, parameters)
        parameters = GrapeSwagger::DocMethods::MoveParams.to_definition(path, parameters, route, @definitions)
      end

      GrapeSwagger::DocMethods::FormatData.to_format(parameters)

      parameters.presence
    end

    def response_object(route, options)
      codes(route).each_with_object({}) do |value, memo|
        value[:message] ||= ''
        memo[value[:code]] = { description: value[:message] ||= '' } unless memo[value[:code]].present?
        memo[value[:code]][:headers] = value[:headers] if value[:headers]

        next build_file_response(memo[value[:code]]) if file_response?(value[:model])

        next build_delete_response(memo, value) if delete_response?(memo, route, value)
        next build_response_for_type_parameter(memo, route, value, options) if value[:type]

        # Explicitly request no model with { model: '' }
        next if value[:model] == ''

        response_model = value[:model] ? expose_params_from_model(value[:model]) : @item
        next unless @definitions[response_model]
        next if response_model.start_with?('Swagger_doc')

        @definitions[response_model][:description] ||= "#{response_model} model"
        build_memo_schema(memo, route, value, response_model, options)
        memo[value[:code]][:examples] = value[:examples] if value[:examples]
      end
    end

    def codes(route)
      http_codes_from_route(route).map do |x|
        x.is_a?(Array) ? { code: x[0], message: x[1], model: x[2], examples: x[3], headers: x[4] } : x
      end
    end

    def success_code?(code)
      status = code.is_a?(Array) ? code.first : code[:code]
      status.between?(200, 299)
    end

    def http_codes_from_route(route)
      if route.http_codes.is_a?(Array) && route.http_codes.any? { |code| success_code?(code) }
        route.http_codes.clone
      else
        success_codes_from_route(route) + default_code_from_route(route) +
          (route.http_codes || route.options[:failure] || [])
      end
    end

    def success_codes_from_route(route)
      if @entity.is_a?(Array)
        return @entity.map do |entity|
          success_code_from_entity(route, entity)
        end
      end

      [success_code_from_entity(route, @entity)]
    end

    def tag_object(route, path)
      version = GrapeSwagger::DocMethods::Version.get(route)
      version = Array(version)
      prefix = route.prefix.to_s.split('/').reject(&:empty?)
      Array(
        path.split('{')[0].split('/').reject(&:empty?).delete_if do |i|
          prefix.include?(i) || version.map(&:to_s).include?(i)
        end.first
      ).presence
    end

    private

    def default_code_from_route(route)
      entity = route.options[:default_response]
      return [] if entity.nil?

      default_code = { code: 'default', message: 'Default Response' }
      if entity.is_a?(Hash)
        default_code[:message] = entity[:message] || default_code[:message]
        default_code[:model] = entity[:model] if entity[:model].present?
      else
        default_code[:model] = entity
      end

      [default_code]
    end

    def build_delete_response(memo, value)
      memo[204] = memo.delete(200)
      value[:code] = 204
    end

    def delete_response?(memo, route, value)
      memo.key?(200) && route.request_method == 'DELETE' && value[:model].nil?
    end

    def build_memo_schema(memo, route, value, response_model, options)
      if memo[value[:code]][:schema] && value[:as]
        memo[value[:code]][:schema][:properties].merge!(build_reference(route, value, response_model, options))

        if value[:required]
          memo[value[:code]][:schema][:required] ||= []
          memo[value[:code]][:schema][:required] << value[:as].to_s
        end

      elsif value[:as]
        memo[value[:code]][:schema] = {
          type: :object,
          properties: build_reference(route, value, response_model, options)
        }
        memo[value[:code]][:schema][:required] = [value[:as].to_s] if value[:required]
      else
        memo[value[:code]][:schema] = build_reference(route, value, response_model, options)
      end
    end

    def build_response_for_type_parameter(memo, _route, value, _options)
      type, format = prepare_type_and_format(value)

      if memo[value[:code]].include?(:schema) && value.include?(:as)
        memo[value[:code]][:schema][:properties].merge!(value[:as] => { type: type, format: format }.compact)
      elsif value.include?(:as)
        memo[value[:code]][:schema] =
          { type: :object, properties: { value[:as] => { type: type, format: format }.compact } }
      else
        memo[value[:code]][:schema] = { type: type }
      end
    end

    def prepare_type_and_format(value)
      data_type = GrapeSwagger::DocMethods::DataType.call(value[:type])

      if GrapeSwagger::DocMethods::DataType.primitive?(data_type)
        GrapeSwagger::DocMethods::DataType.mapping(data_type)
      else
        data_type
      end
    end

    def build_reference(route, value, response_model, settings)
      # TODO: proof that the definition exist, if model isn't specified
      reference = if value.key?(:as)
                    { value[:as] => build_reference_hash(response_model) }
                  else
                    build_reference_hash(response_model)
                  end
      return reference unless value[:code] == 'default' || value[:code] < 300

      if value.key?(:as) && value.key?(:is_array)
        reference[value[:as]] = build_reference_array(reference[value[:as]])
      elsif route.options[:is_array]
        reference = build_reference_array(reference)
      end

      build_root(route, reference, response_model, settings)
    end

    def build_reference_hash(response_model)
      { '$ref' => "#/definitions/#{response_model}" }
    end

    def build_reference_array(reference)
      { type: 'array', items: reference }
    end

    def build_root(route, reference, response_model, settings)
      default_root = response_model.underscore
      default_root = default_root.pluralize if route.options[:is_array]
      case route.settings.dig(:swagger, :root)
      when true
        { type: 'object', properties: { default_root => reference } }
      when false
        reference
      when nil
        settings[:add_root] ? { type: 'object', properties: { default_root => reference } } : reference
      else
        { type: 'object', properties: { route.settings.dig(:swagger, :root) => reference } }
      end
    end

    def file_response?(value)
      value.to_s.casecmp('file').zero?
    end

    def build_file_response(memo)
      memo['schema'] = { type: 'file' }
    end

    def build_request_params(route, settings)
      REQUEST_PARAM_PARSERS.each_with_object({}) do |parser_klass, accum|
        params = parser_klass.parse(
          route,
          accum,
          settings,
          self
        )
        accum.merge!(params.stringify_keys)
      end
    end

    def default_type(params)
      default_param_type = { required: true, type: 'Integer' }
      params.each { |param| param[-1] = param.last.empty? ? default_param_type : param.last }
    end

    def expose_params(value)
      if value.is_a?(Class) && GrapeSwagger.model_parsers.find(value)
        expose_params_from_model(value)
      elsif value.is_a?(String)
        begin
          expose_params(Object.const_get(value.gsub(/\[|\]/, ''))) # try to load class from its name
        rescue NameError
          nil
        end
      end
    end

    def expose_params_from_model(model)
      model = model.constantize if model.is_a?(String)
      model_name = model_name(model)

      return model_name if @definitions.key?(model_name)

      @definitions[model_name] = nil

      parser = GrapeSwagger.model_parsers.find(model)
      raise GrapeSwagger::Errors::UnregisteredParser, "No parser registered for #{model_name}." unless parser

      parsed_response = parser.new(model, self).call

      @definitions[model_name] =
        GrapeSwagger::DocMethods::BuildModelDefinition.parse_params_from_model(parsed_response, model, model_name)

      model_name
    end

    def model_name(name)
      GrapeSwagger::DocMethods::DataType.parse_entity_name(name)
    end

    def hidden?(route, options)
      route_hidden = route.settings.try(:[], :swagger).try(:[], :hidden)
      route_hidden = route.options[:hidden] if route.options.key?(:hidden)
      return route_hidden unless route_hidden.is_a?(Proc)

      options[:token_owner] ? route_hidden.call(send(options[:token_owner].to_sym)) : route_hidden.call
    end

    def hidden_parameter?(value)
      return false if value[:required]

      if value.dig(:documentation, :hidden).is_a?(Proc)
        value.dig(:documentation, :hidden).call
      else
        value.dig(:documentation, :hidden)
      end
    end

    def success_code_from_entity(route, entity)
      default_code = GrapeSwagger::DocMethods::StatusCodes.get[route.request_method.downcase.to_sym]
      if entity.is_a?(Hash)
        default_code[:code] = entity[:code] if entity[:code].present?
        default_code[:model] = entity[:model] if entity[:model].present?
        default_code[:message] = entity[:message] || route.description || default_code[:message].sub('{item}', @item)
        default_code[:examples] = entity[:examples] if entity[:examples]
        default_code[:headers] = entity[:headers] if entity[:headers]
        default_code[:as] = entity[:as] if entity[:as]
        default_code[:is_array] = entity[:is_array] if entity[:is_array]
        default_code[:required] = entity[:required] if entity[:required]
        default_code[:type] = entity[:type] if entity[:type]
      else
        default_code = GrapeSwagger::DocMethods::StatusCodes.get[route.request_method.downcase.to_sym]
        default_code[:model] = entity if entity
        default_code[:message] = route.description || default_code[:message].sub('{item}', @item)
      end

      default_code
    end
  end
end
