require 'grape'
require 'grape-swagger/version'
require 'grape-swagger/errors'
require 'grape-swagger/markdown'
require 'grape-swagger/markdown/kramdown_adapter'
require 'grape-swagger/markdown/redcarpet_adapter'

module Grape
  class API
    class << self
      attr_reader :combined_routes, :combined_namespaces, :combined_namespace_routes, :combined_namespace_identifiers

      def add_swagger_documentation(options = {})
        documentation_class = create_documentation_class

        documentation_class.setup({ target_class: self }.merge(options))
        mount(documentation_class)

        @combined_routes = {}
        routes.each do |route|
          route_path = route.route_path
          route_match = route_path.split(/^.*?#{route.route_prefix.to_s}/).last
          next unless route_match
          route_match = route_match.match('\/([\w|-]*?)[\.\/\(]') || route_match.match('\/([\w|-]*)$')
          next unless route_match
          resource = route_match.captures.first
          next if resource.empty?
          resource.downcase!
          @combined_routes[resource] ||= []
          next if documentation_class.hide_documentation_path && route.route_path.include?(documentation_class.mount_path)
          @combined_routes[resource] << route
        end

        @combined_namespaces = {}
        combine_namespaces(self)

        @combined_namespace_routes = {}
        @combined_namespace_identifiers = {}
        combine_namespace_routes(@combined_namespaces)

        exclusive_route_keys = @combined_routes.keys - @combined_namespaces.keys
        exclusive_route_keys.each { |key| @combined_namespace_routes[key] = @combined_routes[key] }
        documentation_class
      end

      private

      def combine_namespaces(app)
        app.endpoints.each do |endpoint|
          ns = if endpoint.respond_to?(:namespace_stackable)
                 endpoint.namespace_stackable(:namespace).last
               else
                 endpoint.settings.stack.last[:namespace]
               end
          # use the full namespace here (not the latest level only)
          # and strip leading slash
          @combined_namespaces[endpoint.namespace.sub(/^\//, '')] = ns if ns

          combine_namespaces(endpoint.options[:app]) if endpoint.options[:app]
        end
      end

      def combine_namespace_routes(namespaces)
        # iterate over each single namespace
        namespaces.each do |name, namespace|
          # get the parent route for the namespace
          parent_route_name = name.match(%r{^/?([^/]*).*$})[1]
          parent_route = @combined_routes[parent_route_name]
          # fetch all routes that are within the current namespace
          namespace_routes = parent_route.collect do |route|
            route if (route.route_path.start_with?(route.route_prefix ? "/#{route.route_prefix}/#{name}" : "/#{name}") || route.route_path.start_with?((route.route_prefix ? "/#{route.route_prefix}/:version/#{name}" : "/:version/#{name}"))) &&
                     (route.instance_variable_get(:@options)[:namespace] == "/#{name}" || route.instance_variable_get(:@options)[:namespace] == "/:version/#{name}")
          end.compact

          if namespace.options.key?(:swagger) && namespace.options[:swagger][:nested] == false
            # Namespace shall appear as standalone resource, use specified name or use normalized path as name
            if namespace.options[:swagger].key?(:name)
              identifier = namespace.options[:swagger][:name].gsub(/ /, '-')
            else
              identifier = name.gsub(/_/, '-').gsub(/\//, '_')
            end
            @combined_namespace_identifiers[identifier] = name
            @combined_namespace_routes[identifier] = namespace_routes

            # get all nested namespaces below the current namespace
            sub_namespaces = standalone_sub_namespaces(name, namespaces)
            # convert namespace to route names
            sub_ns_paths = sub_namespaces.collect { |ns_name, _| "/#{ns_name}" }
            sub_ns_paths_versioned = sub_namespaces.collect { |ns_name, _| "/:version/#{ns_name}" }
            # get the actual route definitions for the namespace path names
            sub_routes = parent_route.collect do |route|
              route if sub_ns_paths.include?(route.instance_variable_get(:@options)[:namespace]) || sub_ns_paths_versioned.include?(route.instance_variable_get(:@options)[:namespace])
            end.compact
            # add all determined routes of the sub namespaces to standalone resource
            @combined_namespace_routes[identifier].push(*sub_routes)
          else
            # default case when not explicitly specified or nested == true
            standalone_namespaces = namespaces.reject { |_, ns| !ns.options.key?(:swagger) || !ns.options[:swagger].key?(:nested) || ns.options[:swagger][:nested] != false }
            parent_standalone_namespaces = standalone_namespaces.reject { |ns_name, _| !name.start_with?(ns_name) }
            # add only to the main route if the namespace is not within any other namespace appearing as standalone resource
            if parent_standalone_namespaces.empty?
              # default option, append namespace methods to parent route
              @combined_namespace_routes[parent_route_name] = [] unless @combined_namespace_routes.key?(parent_route_name)
              @combined_namespace_routes[parent_route_name].push(*namespace_routes)
            end
          end
        end
      end

      def standalone_sub_namespaces(name, namespaces)
        # assign all nested namespace routes to this resource, too
        # (unless they are assigned to another standalone namespace themselves)
        sub_namespaces = {}
        # fetch all namespaces that are children of the current namespace
        namespaces.each { |ns_name, ns| sub_namespaces[ns_name] = ns if ns_name.start_with?(name) && ns_name != name }
        # remove the sub namespaces if they are assigned to another standalone namespace themselves
        sub_namespaces.each do |sub_name, sub_ns|
          # skip if sub_ns is standalone, too
          next unless sub_ns.options.key?(:swagger) && sub_ns.options[:swagger][:nested] == false
          # remove all namespaces that are nested below this standalone sub_ns
          sub_namespaces.each { |sub_sub_name, _| sub_namespaces.delete(sub_sub_name) if sub_sub_name.start_with?(sub_name) }
        end
        sub_namespaces
      end

      def get_non_nested_params(params)
        # Duplicate the params as we are going to modify them
        dup_params = params.each_with_object(Hash.new) do |(param, value), dparams|
          dparams[param] = value.dup
        end

        dup_params.reject do |param, value|
          is_nested_param = /^#{ Regexp.quote param }\[.+\]$/
          0 < dup_params.count do |p, _|
            match = p.match(is_nested_param)
            dup_params[p][:required] = false if match && !value[:required]
            match
          end
        end
      end

      def parse_array_params(params)
        modified_params = {}
        array_param = nil
        params.each_key do |k|
          if params[k].is_a?(Hash) && params[k][:type] == 'Array'
            array_param = k
          else
            new_key = k
            unless array_param.nil?
              if k.to_s.start_with?(array_param.to_s + '[')
                new_key = array_param.to_s + '[]' + k.to_s.split(array_param)[1]
              end
            end
            modified_params[new_key] = params[k]
          end
        end
        modified_params
      end

      def create_documentation_class
        Class.new(Grape::API) do
          class << self
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

                raw_data_type = value.is_a?(Hash) ? (value[:type] || 'string').to_s : 'string'
                data_type     = case raw_data_type
                                when 'Hash'
                                  'object'
                                when 'Rack::Multipart::UploadedFile'
                                  'File'
                                when 'Virtus::Attribute::Boolean'
                                  'boolean'
                                when 'Boolean', 'Date', 'Integer', 'String', 'Float'
                                  raw_data_type.downcase
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
                description   = value.is_a?(Hash) ? value[:desc] || value[:description] : ''
                required      = value.is_a?(Hash) ? !!value[:required] : false
                default_value = value.is_a?(Hash) ? value[:default] : nil
                is_array      = value.is_a?(Hash) ? (value[:is_array] || false) : false
                enum_values   = value.is_a?(Hash) ? value[:values] : nil
                enum_values   = enum_values.to_a if enum_values && enum_values.is_a?(Range)
                enum_values   = enum_values.call if enum_values && enum_values.is_a?(Proc)

                if value.is_a?(Hash) && value.key?(:param_type)
                  param_type  = value[:param_type]
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
                parsed_params.merge!(defaultValue: default_value) if default_value
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
                name       = parse_entity_name(model)
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
                  id:         model.instance_variable_get(:@root) || name,
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
              type = type.to_s.sub(/^[A-Z]/) { |f| f.downcase } if type.is_a?(Class)
              if is_primitive? type
                { 'type' => type }
              else
                { '$ref' => type }
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
                format: nil,
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
                      type: 'void'
                    }
                    operation[:authorizations] = route.route_authorizations unless route.route_authorizations.nil? || route.route_authorizations.empty?
                    if operation[:parameters].any? { | param | param[:type] == 'File' }
                      operation.merge!(consumes: ['multipart/form-data'])
                    end
                    operation.merge!(responseMessages: http_codes) unless http_codes.empty?

                    if route.route_entity
                      type = @@documentation_class.parse_entity_name(Array(route.route_entity).first)
                      operation.merge!('type' => type)
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
      end
    end
  end
end
