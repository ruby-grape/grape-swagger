module GrapeSwagger
  module DocMethods
    def name
      @@class_name
    end

    def as_markdown(description)
      description && @@markdown ? @@markdown.as_markdown(strip_heredoc(description)) : description
    end

    def parse_params(params, path, method)
      params ||= []

      parsed_array_params = parse_array_params(params)

      non_nested_parent_params = get_non_nested_params(parsed_array_params)

      non_nested_parent_params.map do |param, value|
        items = {}

        raw_data_type = value[:type] if value.is_a?(Hash)
        raw_data_type ||= 'string'
        data_type     = case raw_data_type.to_s
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
                        else
                          @@documentation_class.parse_entity_name(raw_data_type)
                        end

        additional_documentation = value.is_a?(Hash) ? value[:documentation] : nil

        if additional_documentation && value.is_a?(Hash)
          value = additional_documentation.merge(value)
        end

        description   = value.is_a?(Hash) ? value[:desc] || value[:description] : ''
        required      = value.is_a?(Hash) ? !!value[:required] : false
        default_value = value.is_a?(Hash) ? value[:default] : nil
        example       = value.is_a?(Hash) ? value[:example] : nil
        is_array      = value.is_a?(Hash) ? (value[:is_array] || false) : false
        values        = value.is_a?(Hash) ? value[:values] : nil
        enum_values   = parse_enum_values(values)

        if value.is_a?(Hash) && value.key?(:documentation) && value[:documentation].key?(:param_type)
          param_type  = value[:documentation][:param_type]
          if is_array
            items     = { '$ref' => data_type }
            data_type = 'array'
          end
        else
          param_type  = case
                        when path.include?(":#{param}")
                          'path'
                        when %w(POST PUT PATCH).include?(method)
                          if is_primitive?(data_type)
                            'form'
                          else
                            'body'
                          end
                        else
                          'query'
                        end
        end
        name          = (value.is_a?(Hash) && value[:full_name]) || param

        parsed_params = {
          paramType:     param_type,
          name:          name,
          description:   as_markdown(description),
          type:          data_type,
          required:      required,
          allowMultiple: is_array
        }

        parsed_params.merge!(format: 'int32') if data_type == 'integer'
        parsed_params.merge!(format: 'int64') if data_type == 'long'
        parsed_params.merge!(items: items) if items.present?
        parsed_params.merge!(defaultValue: example) if example
        if default_value && example.blank?
          parsed_params.merge!(defaultValue: default_value)
        end
        parsed_params.merge!(enum: enum_values) if enum_values
        parsed_params
      end
    end

    def content_types_for(target_class)
      content_types = (target_class.content_types || {}).values

      if content_types.empty?
        formats       = [target_class.format, target_class.default_format].compact.uniq
        formats       = Grape::Formatter::Base.formatters({}).keys if formats.empty?
        content_types = Grape::ContentTypes::CONTENT_TYPES.select { |content_type, _mime_type| formats.include? content_type }.values
      end

      content_types.uniq
    end

    def parse_info(info)
      {
        contact:            info[:contact],
        description:        as_markdown(info[:description]),
        license:            info[:license],
        licenseUrl:         info[:license_url],
        termsOfServiceUrl:  info[:terms_of_service_url],
        title:              info[:title]
      }.delete_if { |_, value| value.blank? }
    end

    def parse_header_params(params)
      params ||= []

      params.map do |param, value|
        data_type     = 'String'
        description   = value.is_a?(Hash) ? value[:description] : ''
        required      = value.is_a?(Hash) ? !!value[:required] : false
        default_value = value.is_a?(Hash) ? value[:default] : nil
        param_type    = 'header'

        parsed_params = {
          paramType:    param_type,
          name:         param,
          description:  as_markdown(description),
          type:         data_type,
          required:     required
        }

        parsed_params.merge!(defaultValue: default_value) if default_value

        parsed_params
      end
    end

    def parse_path(path, version)
      # adapt format to swagger format
      parsed_path = path.gsub('(.:format)', @@hide_format ? '' : '.{format}')
      # This is attempting to emulate the behavior of
      # Rack::Mount::Strexp. We cannot use Strexp directly because
      # all it does is generate regular expressions for parsing URLs.
      # TODO: Implement a Racc tokenizer to properly generate the
      # parsed path.
      parsed_path = parsed_path.gsub(/:([a-zA-Z_]\w*)/, '{\1}')
      # add the version
      version ? parsed_path.gsub('{version}', version) : parsed_path
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

    def parse_entity_models(models)
      result = {}
      models.each do |model|
        name       = (model.instance_variable_get(:@root) || parse_entity_name(model))
        properties = {}
        required   = []

        model.documentation.each do |property_name, property_info|
          p = property_info.dup

          required << property_name.to_s if p.delete(:required)

          type = if p[:type]
                   p.delete(:type)
                 else
                   exposure = model.exposures[property_name]
                   parse_entity_name(exposure[:using]) if exposure
                 end

          if p.delete(:is_array)
            p[:items] = generate_typeref(type)
            p[:type] = 'array'
          else
            p.merge! generate_typeref(type)
          end

          # rename Grape Entity's "desc" to "description"
          property_description = p.delete(:desc)
          p[:description] = property_description if property_description

          # rename Grape's 'values' to 'enum'
          select_values = p.delete(:values)
          if select_values
            select_values = select_values.call if select_values.is_a?(Proc)
            p[:enum] = select_values
          end

          properties[property_name] = p
        end

        result[name] = {
          id:         name,
          properties: properties
        }
        result[name].merge!(required: required) unless required.empty?
      end

      result
    end

    def models_with_included_presenters(models)
      all_models = models

      models.each do |model|
        # get model references from exposures with a documentation
        nested_models = model.exposures.map do |_, config|
          if config.key?(:documentation)
            model = config[:using]
            model.respond_to?(:constantize) ? model.constantize : model
          end
        end.compact

        # get all nested models recursively
        additional_models = nested_models.map do |nested_model|
          models_with_included_presenters([nested_model])
        end.flatten

        all_models += additional_models
      end

      all_models
    end

    def is_primitive?(type)
      %w(object integer long float double string byte boolean date dateTime).include? type
    end

    def generate_typeref(type)
      type_s = type.to_s.sub(/^[A-Z]/) { |f| f.downcase }
      if is_primitive? type_s
        { 'type' => type_s }
      else
        { '$ref' => parse_entity_name(type) }
      end
    end

    def parse_http_codes(codes, models)
      codes ||= {}
      codes.map do |k, v, m|
        models << m if m
        http_code_hash = {
          code: k,
          message: v
        }
        http_code_hash[:responseModel] = parse_entity_name(m) if m
        http_code_hash
      end
    end

    def strip_heredoc(string)
      indent = string.scan(/^[ \t]*(?=\S)/).min.try(:size) || 0
      string.gsub(/^[ \t]{#{indent}}/, '')
    end

    def parse_base_path(base_path, request)
      if base_path.is_a?(Proc)
        base_path.call(request)
      elsif base_path.is_a?(String)
        URI(base_path).relative? ? URI.join(request.base_url, base_path).to_s : base_path
      else
        request.base_url
      end
    end

    def hide_documentation_path
      @@hide_documentation_path
    end

    def mount_path
      @@mount_path
    end

    def setup(options)
      defaults = {
        target_class: nil,
        mount_path: '/swagger_doc',
        base_path: nil,
        api_version: '0.1',
        markdown: nil,
        hide_documentation_path: false,
        hide_format: false,
        format: :json,
        models: [],
        info: {},
        authorizations: nil,
        root_base_path: true,
        api_documentation: { desc: 'Swagger compatible API description' },
        specific_api_documentation: { desc: 'Swagger compatible API description for specific API' }
      }

      options = defaults.merge(options)

      target_class     = options[:target_class]
      @@mount_path     = options[:mount_path]
      @@class_name     = options[:class_name] || options[:mount_path].gsub('/', '')
      @@markdown       = options[:markdown] ? GrapeSwagger::Markdown.new(options[:markdown]) : nil
      @@hide_format    = options[:hide_format]
      api_version      = options[:api_version]
      authorizations   = options[:authorizations]
      root_base_path   = options[:root_base_path]
      extra_info       = options[:info]
      api_doc          = options[:api_documentation].dup
      specific_api_doc = options[:specific_api_documentation].dup
      @@models         = options[:models] || []

      @@hide_documentation_path = options[:hide_documentation_path]

      if options[:format]
        [:format, :default_format, :default_error_formatter].each do |method|
          send(method, options[:format])
        end
      end

      @@documentation_class = self

      desc api_doc.delete(:desc), api_doc
      get @@mount_path do
        header['Access-Control-Allow-Origin']   = '*'
        header['Access-Control-Request-Method'] = '*'

        namespaces = target_class.combined_namespaces
        namespace_routes = target_class.combined_namespace_routes

        if @@hide_documentation_path
          namespace_routes.reject! { |route, _value| "/#{route}/".index(@@documentation_class.parse_path(@@mount_path, nil) << '/') == 0 }
        end

        namespace_routes_array = namespace_routes.keys.map do |local_route|
          next if namespace_routes[local_route].map(&:route_hidden).all? { |value| value.respond_to?(:call) ? value.call : value }

          url_format  = '.{format}' unless @@hide_format

          original_namespace_name = target_class.combined_namespace_identifiers.key?(local_route) ? target_class.combined_namespace_identifiers[local_route] : local_route
          description = namespaces[original_namespace_name] && namespaces[original_namespace_name].options[:desc]
          description ||= "Operations about #{original_namespace_name.pluralize}"

          {
            path: "/#{local_route}#{url_format}",
            description: description
          }
        end.compact

        output = {
          apiVersion:     api_version,
          swaggerVersion: '1.2',
          produces:       @@documentation_class.content_types_for(target_class),
          apis:           namespace_routes_array,
          info:           @@documentation_class.parse_info(extra_info)
        }

        output[:authorizations] = authorizations unless authorizations.nil? || authorizations.empty?

        output
      end

      desc specific_api_doc.delete(:desc), { params: {
        'name' => {
          desc: 'Resource name of mounted API',
          type: 'string',
          required: true
        }
      }.merge(specific_api_doc.delete(:params) || {}) }.merge(specific_api_doc)

      get "#{@@mount_path}/:name" do
        header['Access-Control-Allow-Origin']   = '*'
        header['Access-Control-Request-Method'] = '*'

        models = []
        routes = target_class.combined_namespace_routes[params[:name]]
        error!('Not Found', 404) unless routes

        visible_ops = routes.reject do |route|
          route.route_hidden.respond_to?(:call) ? route.route_hidden.call : route.route_hidden
        end

        ops = visible_ops.group_by do |route|
          @@documentation_class.parse_path(route.route_path, api_version)
        end

        error!('Not Found', 404) unless ops.any?

        apis = []

        ops.each do |path, op_routes|
          operations = op_routes.map do |route|
            notes       = @@documentation_class.as_markdown(route.route_notes)

            http_codes  = @@documentation_class.parse_http_codes(route.route_http_codes, models)

            models |= @@models if @@models.present?

            models |= Array(route.route_entity) if route.route_entity.present?

            models = @@documentation_class.models_with_included_presenters(models.flatten.compact)

            operation = {
              notes: notes.to_s,
              summary: route.route_description || '',
              nickname: route.route_nickname || (route.route_method + route.route_path.gsub(/[\/:\(\)\.]/, '-')),
              method: route.route_method,
              parameters: @@documentation_class.parse_header_params(route.route_headers) + @@documentation_class.parse_params(route.route_params, route.route_path, route.route_method),
              type: route.route_is_array ? 'array' : 'void'
            }
            operation[:authorizations] = route.route_authorizations unless route.route_authorizations.nil? || route.route_authorizations.empty?
            if operation[:parameters].any? { |param| param[:type] == 'File' }
              operation.merge!(consumes: ['multipart/form-data'])
            end
            operation.merge!(responseMessages: http_codes) unless http_codes.empty?

            if route.route_entity
              type = @@documentation_class.parse_entity_name(Array(route.route_entity).first)
              if route.route_is_array
                operation.merge!(items: { '$ref' => type })
              else
                operation.merge!(type: type)
              end
            end

            operation[:nickname] = route.route_nickname if route.route_nickname
            operation
          end.compact
          apis << {
            path: path,
            operations: operations
          }
        end

        # use custom resource naming if available
        if target_class.combined_namespace_identifiers.key? params[:name]
          resource_path = target_class.combined_namespace_identifiers[params[:name]]
        else
          resource_path = params[:name]
        end
        api_description = {
          apiVersion:     api_version,
          swaggerVersion: '1.2',
          resourcePath:   "/#{resource_path}",
          produces:       @@documentation_class.content_types_for(target_class),
          apis:           apis
        }

        base_path                        = @@documentation_class.parse_base_path(options[:base_path], request)
        api_description[:basePath]       = base_path if base_path && base_path.size > 0 && root_base_path != false
        api_description[:models]         = @@documentation_class.parse_entity_models(models) unless models.empty?
        api_description[:authorizations] = authorizations if authorizations

        api_description
      end
    end
  end
end
