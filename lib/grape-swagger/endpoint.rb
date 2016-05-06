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
        host:           GrapeSwagger::DocMethods::OptionalObject.build(:host, options, request.host_with_port),
        basePath:       GrapeSwagger::DocMethods::OptionalObject.build(:base_path, options, request.env['SCRIPT_NAME']),
        tags:           GrapeSwagger::DocMethods::TagNameDescription.build(options),
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
      GrapeSwagger::DocMethods::MoveParams.to_definition(@paths, @definitions)
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

        @item, path = GrapeSwagger::DocMethods::PathString.build(route.path, options)
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
      method[:description] = description_object(route, options[:markdown])
      method[:produces]    = produces_object(route, options[:produces] || options[:format])
      method[:consumes]    = consumes_object(route, options[:format])
      method[:parameters]  = params_object(route)
      method[:responses]   = response_object(route, options[:markdown])
      method[:tags]        = tag_object(route, options[:version].to_s)
      method[:operationId] = GrapeSwagger::DocMethods::OperationId.build(route, path)
      method.delete_if { |_, value| value.blank? }

      [route.request_method.downcase.to_sym, method]
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
      partition_params(route).map do |param, value|
        value = { required: false }.merge(value) if value.is_a?(Hash)
        _, value = default_type([[param, value]]).first if value == ''
        GrapeSwagger::DocMethods::ParseParams.call(param, value, route)
      end
    end

    def response_object(route, markdown)
      default_code = GrapeSwagger::DocMethods::StatusCodes.get[route.request_method.downcase.to_sym]
      default_code[:model] = @entity if @entity
      default_code[:message] = route.description || default_code[:message].sub('{item}', @item)

      codes = [default_code] + (route.http_codes || route.options[:failure] || [])
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

    def tag_object(route, version)
      Array(route.path.split('{')[0].split('/').reject(&:empty?).delete_if { |i| ((i == route.prefix.to_s) || (i == version)) }.first)
    end

    private

    def partition_params(route)
      declared_params = route.settings[:declared_params] if route.settings[:declared_params].present?
      required, exposed = route.params.partition { |x| x.first.is_a? String }
      required.concat GrapeSwagger::DocMethods::Headers.parse(route) unless route.headers.nil?
      default_type(required)
      default_type(exposed)

      unless declared_params.nil? && route.headers.nil?
        request_params = parse_request_params(required)
      end

      return route.params if route.params.present? && !route.settings[:declared_params].present?
      request_params || {}
    end

    def default_type(params)
      params.each do |param|
        param[-1] = param.last == '' ? { required: true, type: 'Integer' } : param.last
      end
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
        next if x[1].fetch(:documentation, {}).fetch(:in, nil).to_s == 'header'
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
          documented_type = x.last[:type]
          documented_type ||= x.last[:documentation][:type] if x.last[:documentation]
          data_type = GrapeSwagger::DocMethods::DataType.call(documented_type)

          if GrapeSwagger::DocMethods::DataType.primitive?(data_type)
            data = GrapeSwagger::DocMethods::DataType.mapping(data_type)
            memo[x.first] = { type: data.first, format: data.last }
          else
            memo[x.first] = { type: data_type }
          end

          memo[x.first][:enum] = x.last[:values] if x.last[:values] && x.last[:values].is_a?(Array)
        end
        memo[x.first][:description] = x.last[:documentation][:desc] if x.last[:documentation] && x.last[:documentation][:desc]
      end
    end

    def expose_params_from_model(model)
      model_name = model_name(model)

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

    def model_name(name)
      name.respond_to?(:name) ? name.name.demodulize.camelize : name.split('::').last
    end

    def could_it_be_a_model?(value)
      (
        value[:type].to_s.include?('Entity') || value[:type].to_s.include?('Entities')
      ) || (
        value[:type] &&
        value[:type].is_a?(Class) &&
        !GrapeSwagger::DocMethods::DataType.primitive?(value[:type].name.downcase) &&
        !value[:type] == Array
      )
    end

    def hidden?(route)
      route_hidden = route.options[:hidden]
      route_hidden = route_hidden.call if route_hidden.is_a?(Proc)
      route_hidden
    end
  end
end
