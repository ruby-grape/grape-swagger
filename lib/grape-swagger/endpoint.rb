module Grape
  class Endpoint

    PRIMITIVE_MAPPINGS = {
      'integer' => %w(integer int32),
      'long' => %w(integer int64),
      'float' => %w(number float),
      'double' => %w(number double),
      'byte' => %w(string byte),
      'date' => %w(string date),
      'dateTime' => %w(string date-time)
    }

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
    def swagger_object(info, target_class, request, options)
      {
        info:           info,
        swagger:        '2.0',
        produces:       content_types_for(target_class),
        authorizations: options[:authorizations],
        host:           request.env['HTTP_HOST'] || options[:host],
        basePath:       request.env['SCRIPT_NAME'] || options[:base_path]
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
      license = {}
      license[:name] = infos.delete(:license) if infos[:license]
      license[:url] = infos.delete(:license_url) if infos[:license_url]

      license
    end

    # contact
    def contact_object(infos)
      contact = {}
      contact[:contact_name] = infos.delete(:contact_name) if infos[:contact_name]
      contact[:contact_email] = infos.delete(:contact_email) if infos[:contact_email]
      contact[:contact_url] = infos.delete(:contact_url) if infos[:contact_url]

      contact
    end

    # building path and definitions objects
    def path_and_definition_objects(namespace_routes, options)
      @paths = {}
      @definitions = {}
      namespace_routes.keys.each do |key|
        routes = namespace_routes[key]
        path_item(routes, options)
      end

      return @paths, @definitions
    end

    # path object
    def path_item(routes, options)
      paths = {}
      routes.each do |route|
        method_definition = {}

        path = route.route_path
        # always removing format
        path.sub!(/\(\.\w+?\)$/,'')
        path.sub!("(.:format)",'')
        # ... format parama
        path.gsub!(/:(\w+)/,'{\1}')
        # set Item from path
        @item = path.gsub(/\/\{(.+?)\}/,"").split('/').last.capitalize.singularize || 'Item'

        # ... replacing version params throuht submitted version
        if options[:api_version]
          path.sub!('{version}', options[:api_version])
        else
          path.sub!('{version}', '')
        end

        method = route.route_method.downcase.to_sym
        request_params = method_object(method, route, options)

        if @paths.key?(path.to_sym)
          @paths[path.to_sym][method] = request_params
        else
          @paths[path.to_sym] = {method => request_params}
        end
      end
    end

    def method_object(method, route, options)
      methods = {}

      mime_types = options[:format] ? Grape::ContentTypes::CONTENT_TYPES[options[:format]] : Grape::ContentTypes::CONTENT_TYPES[:json]
      methods[:produces] = [mime_types]
      methods[:responses] = response_object(route)

      params = route.route_params
      methods[:parameters] = params_object(route) unless params.empty?

      methods
    end

    def response_object(route)
      codes = default_staus_codes[route.route_method.downcase.to_sym] + (route.route_http_codes || [])

      codes.map!{|x| x.is_a?(Array)? {code: x[0], message: x[1], model: x[2].to_s} : x }

      codes.inject({}) do |h, v|
        h[v[:code]] = { description: v[:message].sub('{item}',@item) }

        response_model = @item
        response_model = expose_params_from_model(v[:model]) if v[:model]

        # TODO: proof that the definition exist, if model isn't specified
        unless response_model.start_with?('Swagger_doc')
          h[v[:code]][:schema] = { '$ref' => "#/definitions/#{response_model}" }
        end
        h
      end
    end

    def default_staus_codes
      {
        get: [{code: 200, message: 'get {item}(s)'}],
        post: [{code: 201, message: 'created {item}'}],
        put: [{code: 200, message: 'updated {item}'}],
        delete: [{code: 200, message: 'deleted {item}'}]
      }
    end

    def params_object(route)
      partition_params(route).map do |param, value|
        parse_request_params(param, value, route.route_path, route.route_method)
      end
    end

    def partition_params(route)
      declared_params = route.route_settings[:declared_params] if route.route_settings[:declared_params].present?
      required, exposed = route.route_params.partition { |x| x.first.is_a? String }

      unless declared_params.nil?
        required_params = declared_params.inject({}) {|h,x| h[x] = required.assoc(x.to_s).last; h }
      end

      unless exposed.nil?
        exposed_params = exposed.inject({}) {|h,x| h[x.first] = x.last; h }
        parse_expose_params(exposed_params, route) if route.route_method == 'GET' || @definitions[@item].nil?
      end

      required_params || {}
    end

    def expose_params_from_model(model)
      model_name = model.name.split('::').last

      properties = model.documentation.inject({}) do |h,x|
        h[x.first] = {type: data_type(x.last)}
        h[x.first][:enum] = x.last[:values] if x.last[:values] && x.last[:values].is_a?(Array)
        h
      end
      @definitions[model_name] = {type: 'object', properties: properties}

      model_name
    end

    def parse_expose_params(params, route)
      return if params.empty?
      properties = params.inject({}) {|h,x| h[x.first] = {type: data_type(x.last)}; h }

      @definitions[@item] = {properties: properties}
    end

    def parse_request_params(param, value, path, method)
      items = {}

      additional_documentation = value.is_a?(Hash) ? value[:documentation] : nil
      data_type = data_type(value)

      if additional_documentation && value.is_a?(Hash)
        value = additional_documentation.merge(value)
      end

      description          = value.is_a?(Hash) ? value[:desc] || value[:description] : nil
      required             = value.is_a?(Hash) ? !!value[:required] : false
      default_value        = value.is_a?(Hash) ? value[:default] : nil
      example              = value.is_a?(Hash) ? value[:example] : nil
      is_array             = value.is_a?(Hash) ? (value[:is_array] || false) : false
      values               = value.is_a?(Hash) ? value[:values] : nil
      name                 = (value.is_a?(Hash) && value[:full_name]) || param
      enum_or_range_values = parse_enum_or_range_values(values)

      parsed_params = {
        in:            param_type(value, data_type, path, param, method, is_array),
        name:          name,
        description:   description,
        type:          data_type,
        required:      required,
        allowMultiple: is_array
      }

      if PRIMITIVE_MAPPINGS.key?(data_type)
        parsed_params[:type], parsed_params[:format] = PRIMITIVE_MAPPINGS[data_type]
      end

      parsed_params[:items] = items if items.present?

      parsed_params[:defaultValue] = example if example
      if default_value && example.blank?
        parsed_params[:defaultValue] = default_value
      end

      parsed_params.merge!(enum_or_range_values) if enum_or_range_values
      parsed_params
    end

    # helper methods
    def data_type(value)
      raw_data_type = value[:type] if value.is_a?(Hash)
      raw_data_type ||= 'string'
      case raw_data_type.to_s
      when 'Hash'
        'object'
      when 'Rack::Multipart::UploadedFile'
        'File'
      when 'Virtus::Attribute::Boolean'
        'boolean'
      when 'Boolean', 'Date', 'Integer', 'String', 'Float'
        raw_data_type.to_s.downcase
      when 'BigDecimal'
        'long'
      when 'DateTime'
        'dateTime'
      when 'Numeric'
        'double'
      when 'Symbol'
        'string'
      when /^\[(?<type>.*)\]$/
        items[:type] = Regexp.last_match[:type].downcase
        if PRIMITIVE_MAPPINGS.key?(items[:type])
          items[:type], items[:format] = PRIMITIVE_MAPPINGS[items[:type]]
        end
        'array'
      else
        parse_entity_name(raw_data_type)
      end
    end

    def param_type(value, data_type, path, param, method, is_array)
      if value.is_a?(Hash) && value.key?(:documentation) && value[:documentation].key?(:param_type)
        param_type = value[:documentation][:param_type]
        if is_array
          items     = { '$ref' => data_type }
          data_type = 'array'
        end
      else
        param_type = case
                     when path.include?("{#{param}}")
                       'path'
                     when %w(POST PUT PATCH).include?(method)
                       if is_primitive?(data_type)
                         'formData'
                       else
                         'body'
                       end
                     else
                       'query'
                      end
                    end
    end

    def parse_enum_or_range_values(values)
      case values
      when Range
        parse_range_values(values) if values.first.is_a?(Integer)
      when Proc
        values_result = values.call
        if values_result.is_a?(Range) && values_result.first.is_a?(Integer)
          parse_range_values(values_result)
        else
          { enum: values_result }
        end
      else
        { enum: values } if values
      end
    end

    def parse_range_values(values)
      { minimum: values.first, maximum: values.last }
    end

    def parse_entity_name(model)
      if model.respond_to?(:entity_name)
        model.entity_name
      else
        name = model.to_s
        entity_parts = name.split('::')
        entity_parts.reject! { |p| p == 'Entity' || p == 'Entities' }
        entity_parts.join('::')
      end
    end

    def is_primitive?(type)
      %w(object integer long float double string byte boolean date dateTime).include? type
    end

    def as_markdown(details)
      # description && @@markdown ? @@markdown.as_markdown(strip_heredoc(description)) : description
    end

    def strip_heredoc(string)
      indent = string.scan(/^[ \t]*(?=\S)/).min.try(:size) || 0
      string.gsub(/^[ \t]{#{indent}}/, '')
    end
  end
end
