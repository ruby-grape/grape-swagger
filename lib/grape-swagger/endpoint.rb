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
        info:           info_object(options[:info].merge(version: options[:api_version])),
        swagger:        '2.0',
        produces:       content_types_for(target_class),
        authorizations: options[:authorizations],
        host:           GrapeSwagger::DocMethods::OptionalObject.build(:host, options, request.env['HTTP_HOST']),
        basePath:       GrapeSwagger::DocMethods::OptionalObject.build(:base_path, options, request.env['SCRIPT_NAME']),
        tags:           GrapeSwagger::DocMethods::TagNameDescription.build(options),
        schemes:        options[:scheme]
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
        next if hidden?(route)

        @item, path = GrapeSwagger::DocMethods::PathString.build(route.route_path, options)
        @entity = route.route_entity || route.route_success

        # ... replacing version params through submitted version

        method = route.route_method.downcase.to_sym
        request_params = method_object(route, options, path)

        if @paths.key?(path.to_sym)
          @paths[path.to_sym][method] = request_params
        else
          @paths[path.to_sym] = { method => request_params }
        end

        GrapeSwagger::DocMethods::Extensions.add(@paths[path.to_sym], @definitions, route)
      end
    end

    def method_object(route, options, path)
      method = {}
      method[:description] = description_object(route, options[:markdown])
      method[:headers]     = route.route_headers if route.route_headers
      method[:produces]    = produces_object(route, options[:produces] || options[:format])
      method[:consumes]    = consumes_object(route, options[:format])
      method[:parameters]  = params_object(route)
      method[:responses]   = response_object(route)
      method[:tags]        = tag_object(route, options[:version])
      method[:operationId] = GrapeSwagger::DocMethods::OperationId.build(route.route_method, path)
      method.delete_if { |_, value| value.blank? }
    end

    def description_object(route, markdown)
      description = route.route_desc if route.route_desc.present?
      description = route.route_detail if route.route_detail.present?
      description = markdown.markdown(description).chomp if markdown
      description
    end

    def consumes_object(route, format)
      method = route.route_method.downcase.to_sym
      # require 'pry'; binding.pry if [:post, :put].include?(method)
      format = route.route_settings[:description][:consumes] if route.route_settings[:description] && route.route_settings[:description][:consumes]
      mime_types = GrapeSwagger::DocMethods::ProducesConsumes.call(format) if [:post, :put].include?(method)

      mime_types
    end

    def produces_object(route, format)
      mime_types = GrapeSwagger::DocMethods::ProducesConsumes.call(format)

      route_mime_types = [:route_formats, :route_content_types, :route_produces].map do |producer|
        possible = route.send(producer)
        GrapeSwagger::DocMethods::ProducesConsumes.call(possible) if possible.present?
      end.flatten.compact.uniq

      route_mime_types.present? ? route_mime_types : mime_types
    end

    def response_object(route)
      default_code = default_staus_codes[route.route_method.downcase.to_sym]
      default_code[:model] = @entity if @entity
      default_code[:message] = route.route_description || default_code[:message].sub('{item}', @item)

      codes = [default_code] + (route.route_http_codes || route.route_failure || [])

      codes.map! { |x| x.is_a?(Array) ? { code: x[0], message: x[1], model: x[2] } : x }

      codes.each_with_object({}) do |value, memo|
        memo[value[:code]] = { description: value[:message] }

        response_model = @item
        response_model = expose_params_from_model(value[:model]) if value[:model]

        next unless !response_model.start_with?('Swagger_doc') &&
                    ((@definitions[response_model] && value[:code].to_s.start_with?('2')) || value[:model])

        # TODO: proof that the definition exist, if model isn't specified
        memo[value[:code]][:schema] = if route.route_is_array
                                        { 'type' => 'array', 'items' => { '$ref' => "#/definitions/#{response_model}" } }
                                      else
                                        { '$ref' => "#/definitions/#{response_model}" }
                                      end
      end
    end

    def default_staus_codes
      {
        get: { code: 200, message: 'get {item}(s)' },
        post: { code: 201, message: 'created {item}' },
        put: { code: 200, message: 'updated {item}' },
        patch: { code: 200, message: 'patched {item}' },
        delete: { code: 200, message: 'deleted {item}' }
      }
    end

    def params_object(route)
      partition_params(route).map do |param, value|
        value = { required: false }.merge(value) if value.is_a?(Hash)
        GrapeSwagger::DocMethods::ParseParams.call(param, value, route)
      end
    end

    def partition_params(route)
      declared_params = route.route_settings[:declared_params] if route.route_settings[:declared_params].present?
      required, exposed = route.route_params.partition { |x| x.first.is_a? String }

      unless declared_params.nil?
        required_params = parse_request_params(required)
      end

      if !exposed.empty? && !@entity
        exposed_params = exposed.each_with_object({}) { |x, memo| memo[x.first] = x.last }
        properties = parse_response_params(exposed_params)

        @definitions[@item] = { properties: properties }
      end

      return route.route_params if route.route_params && !route.route_settings[:declared_params].present?
      required_params || {}
    end

    def parse_request_params(required)
      required.each_with_object({}) do |param, memo|
        @array_key = param.first.to_s.gsub('[', '[][') if param.last[:type] == 'Array'
        possible_key = param.first.to_s.gsub('[', '[][')
        if @array_key && possible_key.start_with?(@array_key)
          key = possible_key
          param.last[:is_array] = true
        else
          key = param.first
        end
        memo[key] = param.last unless param.last[:type] == 'Hash' || param.last[:type] == 'Array' && !param.last.key?(:documentation)
      end
    end

    def parse_response_params(params)
      return if params.nil?

      params.each_with_object({}) do |x, memo|
        x[0] = x.last[:as] if x.last[:as]

        model = x.last[:using] if x.last[:using].present?
        model ||= x.last[:documentation][:type] if x.last[:documentation] && could_it_be_a_model?(x.last[:documentation])

        if model
          name = expose_params_from_model(model)
          memo[x.first] = if x.last[:documentation] && x.last[:documentation][:is_array]
                            { 'type' => 'array', 'items' => { '$ref' => "#/definitions/#{name}" } }
                          else
                            { '$ref' => "#/definitions/#{name}" }
                          end
        else
          memo[x.first] = { type: GrapeSwagger::DocMethods::DataType.call(x.last[:documentation] || x.last) }
          memo[x.first][:enum] = x.last[:values] if x.last[:values] && x.last[:values].is_a?(Array)
        end
      end
    end

    def expose_params_from_model(model)
      model_name = model.respond_to?(:name) ? model.name.demodulize.camelize : model.split('::').last

      # DONE: has to be adept, to be ready for grape-entity >0.5.0
      # TODO: this should only be a temporary hack ;)
      if GrapeEntity::VERSION =~ /0\.4\.\d/
        parameters = model.exposures ? model.exposures : model.documentation
      elsif GrapeEntity::VERSION =~ /0\.5\.\d/
        parameters = model.root_exposures.each_with_object({}) do |value, memo|
          memo[value.attribute] = value.send(:options)
        end
      end
      properties = parse_response_params(parameters)

      @definitions[model_name] = { type: 'object', properties: properties }

      model_name
    end

    def could_it_be_a_model?(value)
      (
        value[:type].to_s.include?('Entity') || value[:type].to_s.include?('Entities')
      ) || (
        value[:type] &&
        value[:type].is_a?(Class) &&
        !GrapeSwagger::DocMethods::ParseParams.primitive?(value[:type].name.downcase) &&
        !value[:type] == Array
      )
    end

    def hidden?(route)
      if route.route_hidden
        return route.route_hidden.is_a?(Proc) ? route.route_hidden.call : route.route_hidden
      end

      false
    end

    def tag_object(route, version)
      Array(route.route_path.split('{')[0].split('/').reject(&:empty?).delete_if { |i| ((i == route.route_prefix.to_s) || (i == version)) }.first)
    end
  end
end
