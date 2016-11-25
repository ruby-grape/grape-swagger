require 'active_support'
require 'active_support/core_ext/string/inflections.rb'

module Grape
  class Endpoint
    def content_types_for(target_class)
      content_types = (target_class.content_types || {}).values

      if content_types.empty?
        formats       = [target_class.format, target_class.default_format].compact.uniq
        formats       = Grape::Formatter::Base.formatters({}).keys if formats.empty?
        content_types = Grape::ContentTypes::CONTENT_TYPES.select { |content_type, _mime_type| formats.include? content_type }.values
      end

      content_types.uniq
    end

    # swagger spec2.0 related parts
    #
    # required keys for SwaggerObject
    def swagger_object(target_class, request, options)
      {
        info:           info_object(options[:info].merge(version: options[:doc_version])),
        swagger:        '2.0',
        produces:       content_types_for(target_class),
        authorizations: options[:authorizations],
        securityDefinitions: options[:security_definitions],
        host:           GrapeSwagger::DocMethods::OptionalObject.build(:host, options, request),
        basePath:       GrapeSwagger::DocMethods::OptionalObject.build(:base_path, options, request),
        schemes:        options[:schemes].is_a?(String) ? [options[:schemes]] : options[:schemes]
      }.delete_if { |_, value| value.blank? }
    end

    # building info object
    def info_object(infos)
      {
        title:             infos[:title] || 'API title',
        description:       infos[:description],
        termsOfServiceUrl: infos[:terms_of_service_url],
        contact:           contact_object(infos),
        license:           license_object(infos),
        version:           infos[:version]
      }.delete_if { |_, value| value.blank? }
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
    def path_and_definition_objects(namespace_routes, options)
      @paths = {}
      @definitions = {}
      namespace_routes.keys.each do |key|
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
      method[:description] = description_object(route, options[:markdown])
      method[:produces]    = produces_object(route, options[:produces] || options[:format])
      method[:consumes]    = consumes_object(route, options[:format])
      method[:parameters]  = params_object(route)
      method[:security]    = security_object(route)
      method[:responses]   = response_object(route, options[:markdown])
      method[:tags]        = route.options.fetch(:tags, tag_object(route))
      method[:operationId] = GrapeSwagger::DocMethods::OperationId.build(route, path)
      method.delete_if { |_, value| value.blank? }

      [route.request_method.downcase.to_sym, method]
    end

    def security_object(route)
      route.options[:security] if route.options.key?(:security)
    end

    def summary_object(route)
      summary = route.options[:desc] if route.options.key?(:desc)
      summary = route.description if route.description.present?
      summary = route.options[:summary] if route.options.key?(:summary)

      summary
    end

    def description_object(route, markdown)
      description = route.options[:desc] if route.options.key?(:desc)
      description = route.description if route.description.present?
      description = "# #{description} " if markdown
      description += "\n #{route.options[:detail]}" if route.options.key?(:detail)
      description = markdown.markdown(description.to_s).chomp if markdown

      description
    end

    def produces_object(route, format)
      mime_types = GrapeSwagger::DocMethods::ProducesConsumes.call(format)

      route_mime_types = [:formats, :content_types, :produces].map do |producer|
        possible = route.options[producer]
        GrapeSwagger::DocMethods::ProducesConsumes.call(possible) if possible.present?
      end.flatten.compact.uniq

      route_mime_types.present? ? route_mime_types : mime_types
    end

    def consumes_object(route, format)
      method = route.request_method.downcase.to_sym
      format = route.settings[:description][:consumes] if route.settings[:description] && route.settings[:description][:consumes]
      mime_types = GrapeSwagger::DocMethods::ProducesConsumes.call(format) if [:post, :put].include?(method)

      mime_types
    end

    def params_object(route)
      parameters = partition_params(route).map do |param, value|
        value = { required: false }.merge(value) if value.is_a?(Hash)
        _, value = default_type([[param, value]]).first if value == ''
        if value[:type]
          expose_params(value[:type])
        elsif value[:documentation]
          expose_params(value[:documentation][:type])
        end
        GrapeSwagger::DocMethods::ParseParams.call(param, value, route, @definitions)
      end

      if GrapeSwagger::DocMethods::MoveParams.can_be_moved?(parameters, route.request_method)
        parameters = GrapeSwagger::DocMethods::MoveParams.to_definition(parameters, route, @definitions)
      end

      parameters
    end

    def response_object(route, markdown)
      codes = (route.http_codes || route.options[:failure] || [])

      codes = apply_success_codes(route) + codes
      codes.map! { |x| x.is_a?(Array) ? { code: x[0], message: x[1], model: x[2] } : x }

      codes.each_with_object({}) do |value, memo|
        memo[value[:code]] = { description: value[:message] }

        response_model = @item
        response_model = expose_params_from_model(value[:model]) if value[:model]

        if memo.key?(200) && route.request_method == 'DELETE' && value[:model].nil?
          memo[204] = memo.delete(200)
          value[:code] = 204
        end

        next if memo.key?(204)
        next unless !response_model.start_with?('Swagger_doc') &&
                    ((@definitions[response_model] && value[:code].to_s.start_with?('2')) || value[:model])

        @definitions[response_model][:description] = description_object(route, markdown)
        # TODO: proof that the definition exist, if model isn't specified
        memo[value[:code]][:schema] = if route.options[:is_array]
                                        { 'type' => 'array', 'items' => { '$ref' => "#/definitions/#{response_model}" } }
                                      else
                                        { '$ref' => "#/definitions/#{response_model}" }
                                      end
      end
    end

    def apply_success_codes(route)
      default_code = GrapeSwagger::DocMethods::StatusCodes.get[route.request_method.downcase.to_sym]
      if @entity.is_a?(Hash)
        default_code[:code] = @entity[:code] if @entity[:code].present?
        default_code[:model] = @entity[:model] if @entity[:model].present?
        default_code[:message] = @entity[:message] || route.description || default_code[:message].sub('{item}', @item)
      else
        default_code = GrapeSwagger::DocMethods::StatusCodes.get[route.request_method.downcase.to_sym]
        default_code[:model] = @entity if @entity
        default_code[:message] = route.description || default_code[:message].sub('{item}', @item)
      end

      [default_code]
    end

    def tag_object(route)
      version = route.version
      # for grape version 0.14.0..0.16.2, the version can be a string like '[:v1, :v2]'
      # for grape version bigger than 0.16.2, the version can be a array like [:v1, :v2]
      version = eval(version) if version.start_with?('[') && version.end_with?(']') # eval('[:v1, :v2]') for grape lower than 0.17
      version = [version] unless version.is_a?(Array)
      [route.path.split('{')[0]
            .split('/').reject(&:empty?)
            .delete_if do |i|
              ((i == route.prefix.to_s) || (version.map(&:to_s).include?(i)))
            end.first]
    end

    private

    def partition_params(route)
      declared_params = route.settings[:declared_params] if route.settings[:declared_params].present?
      required, exposed = route.params.partition { |x| x.first.is_a? String }
      required = GrapeSwagger::DocMethods::Headers.parse(route) + required unless route.headers.nil?

      default_type(required)
      default_type(exposed)

      request_params = unless declared_params.nil? && route.headers.nil?
                         parse_request_params(required)
                       end || {}

      request_params = route.params.merge(request_params) if route.params.present? && !route.settings[:declared_params].present?

      request_params
    end

    def default_type(params)
      params.each do |param|
        param[-1] = param.last == '' ? { required: true, type: 'Integer' } : param.last
      end
    end

    def parse_request_params(params)
      array_key = nil
      params.select { |param| public_parameter?(param) }.each_with_object({}) do |param, memo|
        name, options = *param
        param_type = options[:type]
        param_type = param_type.to_s unless param_type.nil?
        array_key = name.to_s if param_type_is_array?(param_type)
        options[:is_array] = true if array_key && name.start_with?(array_key)
        memo[name] = options unless %w(Hash Array).include?(param_type) && !options.key?(:documentation)
      end
    end

    def param_type_is_array?(param_type)
      return false unless param_type
      return true if param_type == 'Array'
      param_types = param_type.match(/\[(.*)\]$/)
      return false unless param_types
      param_types = param_types[0].split(',') if param_types
      param_types.size == 1
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

      properties = parser.new(model, self).call
      raise GrapeSwagger::Errors::SwaggerSpec, "Empty model #{model_name}, swagger 2.0 doesn't support empty definitions." unless properties && properties.any?

      @definitions[model_name] = GrapeSwagger::DocMethods::BuildModelDefinition.build(model, properties)

      model_name
    end

    def model_name(name)
      GrapeSwagger::DocMethods::DataType.parse_entity_name(name)
    end

    def hidden?(route, options)
      route_hidden = route.options[:hidden]
      return route_hidden unless route_hidden.is_a?(Proc)
      options[:token_owner] ? route_hidden.call(send(options[:token_owner].to_sym)) : route_hidden.call
    end

    def public_parameter?(param)
      param_options = param.last
      return true unless param_options.key?(:documentation) && !param_options[:required]
      param_hidden = param_options[:documentation].fetch(:hidden, false)
      param_hidden = param_hidden.call if param_hidden.is_a?(Proc)
      !param_hidden
    end
  end
end
