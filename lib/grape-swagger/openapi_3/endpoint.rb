# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/string/inflections'
require 'grape-swagger/endpoint/params_parser'

module Grape
  class Endpoint
    def content_types_for(target_class)
      content_types = (target_class.content_types || {}).values

      if content_types.empty?
        formats       = [target_class.format, target_class.default_format].compact.uniq
        formats       = Grape::Formatter.formatters({}).keys if formats.empty?
        content_types = Grape::ContentTypes::CONTENT_TYPES.select do |content_type, _mime_type|
          formats.include? content_type
        end.values
      end

      content_types.uniq
    end

    # openapi 3.0 related parts
    #
    # required keys for SwaggerObject
    def swagger_object(_target_class, _request, options)
      object = {
        info:                info_object(options[:info].merge(version: options[:doc_version])),
        openapi:             '3.0.0',
        security:            options[:security],
        authorizations:      options[:authorizations],
        servers:             options[:servers].is_a?(Hash) ? [options[:servers]] : options[:servers]
      }

      if options[:security_definitions] || options[:security]
        components = { securitySchemes: options[:security_definitions] }
        components.delete_if { |_, value| value.blank? }
        object[:components] = components
      end

      GrapeSwagger::DocMethods::Extensions.add_extensions_to_root(options, object)
      object.delete_if { |_, value| value.blank? }
    end

    # building info object
    def info_object(infos)
      result = {
        title:             infos[:title] || 'API title',
        description:       infos[:description],
        termsOfService:    infos[:terms_of_service_url],
        contact:           contact_object(infos),
        license:           license_object(infos),
        version:           infos[:version]
      }

      GrapeSwagger::DocMethods::Extensions.add_extensions_to_info(infos, result)

      result.delete_if { |_, value| value.blank? }
    end

    # sub-objects of info object
    # license
    def license_object(infos)
      {
        name: infos.delete(:license),
        url:  infos.delete(:license_url)
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
    def path_and_definition_objects(namespace_routes, target_class, options)
      @content_types = content_types_for(target_class)

      @paths = {}
      @definitions = {}
      namespace_routes.each_key do |key|
        routes = namespace_routes[key]
        path_item(routes, options)
      end

      add_definitions_from options[:models]
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

      parameters = params_object(route, options, path).partition { |p| p[:in] == 'body' || p[:in] == 'formData' }

      method[:parameters]  = parameters.last
      method[:security]    = security_object(route)
      if %w[POST PUT PATCH].include?(route.request_method)
        consumes = consumes_object(route, options[:format])
        method[:requestBody] = response_body_object(route, path, consumes, parameters.first)
      end

      produces = produces_object(route, options[:produces] || options[:format])

      method[:responses]   = response_object(route, produces)
      method[:tags]        = route.options.fetch(:tags, tag_object(route, path))
      method[:operationId] = GrapeSwagger::DocMethods::OperationId.build(route, path)
      method[:deprecated] = deprecated_object(route)
      method.delete_if { |_, value| value.blank? }

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
      description ||= ''

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

    def params_object(route, options, path)
      parameters = partition_params(route, options).map do |param, value|
        value = { required: false }.merge(value) if value.is_a?(Hash)
        _, value = default_type([[param, value]]).first if value == ''
        if value[:type]
          expose_params(value[:type])
        elsif value[:documentation]
          expose_params(value[:documentation][:type])
        end
        GrapeSwagger::DocMethods::ParseParams.call(param, value, path, route, @definitions)
      end

      if GrapeSwagger::DocMethods::MoveParams.can_be_moved?(parameters, route.request_method)
        parameters = GrapeSwagger::DocMethods::MoveParams.to_definition(path, parameters, route, @definitions)
      end

      parameters
    end

    def response_body_object(_, _, consumes, parameters)
      body_parameters, form_parameters = parameters.partition { |p| p[:in] == 'body' }
      result = consumes.map { |c| response_body_parameter_object(body_parameters, c) }

      unless form_parameters.empty?
        result << response_body_parameter_object(form_parameters, 'application/x-www-form-urlencoded')
      end

      { content: result.to_h }
    end

    def response_body_parameter_object(parameters, content_type)
      properties = parameters.map { |value| [value[:name], value.except(:name, :in, :required, :schema).merge(value[:schema])] }.to_h
      required_values = parameters.select { |param| param[:required] }.map { |required| required[:name] }
      result = { schema: { type: :object, properties: properties } }
      result[:schema][:required] = required_values unless required_values.empty?
      [content_type, result]
    end

    def response_object(route, content_types)
      codes = http_codes_from_route(route)
      codes.map! { |x| x.is_a?(Array) ? { code: x[0], message: x[1], model: x[2], examples: x[3], headers: x[4] } : x }

      codes.each_with_object({}) do |value, memo|
        value[:message] ||= ''
        memo[value[:code]] = { description: value[:message] }

        memo[value[:code]][:headers] = value[:headers] if value[:headers]

        next build_file_response(memo[value[:code]]) if file_response?(value[:model])

        response_model = @item
        response_model = expose_params_from_model(value[:model]) if value[:model]

        if memo.key?(200) && route.request_method == 'DELETE' && value[:model].nil?
          memo[204] = memo.delete(200)
          value[:code] = 204
        end

        next if value[:code] == 204 || value[:code] == 201

        model = !response_model.start_with?('Swagger_doc') && (@definitions[response_model] || value[:model])

        ref = build_reference(route, value, response_model)
        memo[value[:code]][:content] = content_types.map do |c|
          if model
            [c, { schema: ref }]
          else
            [c, {}]
          end
        end.to_h

        next unless model

        @definitions[response_model][:description] = description_object(route)

        memo[value[:code]][:examples] = value[:examples] if value[:examples]
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
        success_codes_from_route(route) + (route.http_codes || route.options[:failure] || [])
      end
    end

    def success_codes_from_route(route)
      default_code = GrapeSwagger::DocMethods::StatusCodes.get[route.request_method.downcase.to_sym]
      if @entity.is_a?(Hash)
        default_code[:code] = @entity[:code] if @entity[:code].present?
        default_code[:model] = @entity[:model] if @entity[:model].present?
        default_code[:message] = @entity[:message] || route.description || default_code[:message].sub('{item}', @item)
        default_code[:examples] = @entity[:examples] if @entity[:examples]
        default_code[:headers] = @entity[:headers] if @entity[:headers]
      else
        default_code = GrapeSwagger::DocMethods::StatusCodes.get[route.request_method.downcase.to_sym]
        default_code[:model] = @entity if @entity
        default_code[:message] = route.description || default_code[:message].sub('{item}', @item)
      end

      [default_code]
    end

    def tag_object(route, path)
      version = GrapeSwagger::DocMethods::Version.get(route)
      version = [version] unless version.is_a?(Array)
      Array(
        path.split('{')[0].split('/').reject(&:empty?).delete_if do |i|
          i == route.prefix.to_s || version.map(&:to_s).include?(i)
        end.first
      )
    end

    private

    def build_reference(route, value, response_model)
      # TODO: proof that the definition exist, if model isn't specified
      reference = { '$ref' => "#/components/schemas/#{response_model}" }
      route.options[:is_array] && value[:code] < 300 ? { type: 'array', items: reference } : reference
    end

    def file_response?(value)
      value.to_s.casecmp('file').zero? ? true : false
    end

    def build_file_response(memo)
      memo['schema'] = { type: 'file' }
    end

    def partition_params(route, settings)
      declared_params = route.settings[:declared_params] if route.settings[:declared_params].present?
      required = merge_params(route)
      required = GrapeSwagger::DocMethods::Headers.parse(route) + required unless route.headers.nil?

      default_type(required)

      request_params = unless declared_params.nil? && route.headers.nil?
                         GrapeSwagger::Endpoint::ParamsParser.parse_request_params(required, settings)
                       end || {}

      request_params.empty? ? required : request_params
    end

    def merge_params(route)
      param_keys = route.params.keys
      route.params.delete_if { |key| key.is_a?(String) && param_keys.include?(key.to_sym) }.to_a
    end

    def default_type(params)
      default_param_type = { required: true, type: 'Integer' }
      params.each { |param| param[-1] = param.last == '' ? default_param_type : param.last }
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
      model = model.is_a?(String) ? model.constantize : model
      model_name = model_name(model)

      return model_name if @definitions.key?(model_name)

      @definitions[model_name] = nil

      parser = GrapeSwagger.model_parsers.find(model)
      raise GrapeSwagger::Errors::UnregisteredParser, "No parser registered for #{model_name}." unless parser

      properties, required = parser.new(model, self).call
      unless properties&.any?
        raise GrapeSwagger::Errors::SwaggerSpec,
              "Empty model #{model_name}, openapi 3.0 doesn't support empty definitions."
      end

      @definitions[model_name] = GrapeSwagger::DocMethods::BuildModelDefinition.build(model, properties, required)

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
  end
end
