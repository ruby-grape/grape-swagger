require 'kramdown'

module Grape
  class API
    class << self
      attr_reader :combined_routes

      def add_swagger_documentation(options={})
        documentation_class = create_documentation_class

        documentation_class.setup({:target_class => self}.merge(options))
        mount(documentation_class)

        @combined_routes = {}

        routes.each do |route|
          route_match = route.route_path.split(route.route_prefix).last.match('\/([\w|-]*?)[\.\/\(]')
          next if route_match.nil?
          resource = route_match.captures.first
          next if resource.empty?
          resource.downcase!

          @combined_routes[resource] ||= []

          unless @@hide_documentation_path and route.route_path.include?(@@mount_path)
            @combined_routes[resource] << route
          end
        end
      end

      private

      def create_documentation_class

        Class.new(Grape::API) do
          class << self
            def name
              @@class_name
            end
          end

          def self.setup(options)
            defaults = {
              :target_class             => nil,
              :mount_path               => '/swagger_doc',
              :base_path                => nil,
              :api_version              => '0.1',
              :markdown                 => false,
              :hide_documentation_path  => false,
              :hide_format              => false,
              :format                   => nil,
              :models                   => [],
              :info                     => {},
              :authorizations           => nil,
              :root_base_path           => true,
              :include_base_url         => true
            }

            options = defaults.merge(options)

            target_class     = options[:target_class]
            @@mount_path     = options[:mount_path]
            @@class_name     = options[:class_name] || options[:mount_path].gsub('/', '')
            @@markdown       = options[:markdown]
            @@hide_format    = options[:hide_format]
            api_version      = options[:api_version]
            base_path        = options[:base_path]
            authorizations   = options[:authorizations]
            include_base_url = options[:include_base_url]
            root_base_path   = options[:root_base_path]
            extra_info       = options[:info]
            @@models         = options[:models] || []

            @@hide_documentation_path = options[:hide_documentation_path]

            if options[:format]
              [:format, :default_format, :default_error_formatter].each do |method|
                send(method, options[:format])
              end
            end

            desc 'Swagger compatible API description'
            get @@mount_path do
              header['Access-Control-Allow-Origin']   = '*'
              header['Access-Control-Request-Method'] = '*'

              routes = target_class::combined_routes

              if @@hide_documentation_path
                routes.reject!{ |route, value| "/#{route}/".index(parse_path(@@mount_path, nil) << '/') == 0 }
              end

              routes_array = routes.keys.map do |local_route|
                next if routes[local_route].all?(&:route_hidden)

                url_base    = parse_path(route.route_path.gsub('(.:format)', ''), route.route_version) if include_base_url
                url_format  = '.{format}' unless @@hide_format
                {
                  :path => "/#{local_route}#{url_format}",
                  :description => "Operations about #{local_route.pluralize}"
                }
              end.compact

              output = {
                apiVersion:     api_version,
                swaggerVersion: "1.2",
                produces:       content_types_for(target_class),
                apis:           routes_array,
                info:           parse_info(extra_info)
              }

              output[:authorizations] = authorizations unless (authorizations.nil? || authorizations.empty?)

              output
            end

            desc 'Swagger compatible API description for specific API', :params => {
              "name" => {
                :desc     => "Resource name of mounted API",
                :type     => "string",
                :required => true
              }
            }
            get "#{@@mount_path}/:name" do
              header['Access-Control-Allow-Origin']   = '*'
              header['Access-Control-Request-Method'] = '*'

              models = []
              routes = target_class::combined_routes[params[:name]]

              ops = routes.reject(&:route_hidden).group_by do |route|
                parse_path(route.route_path, api_version)
              end

              apis = []

              ops.each do |path, routes|
                operations = routes.map do |route|
                  notes       = as_markdown(route.route_notes)
                  http_codes  = parse_http_codes(route.route_http_codes)

                  models <<  if @@models.present?
                               @@models
                             else route.route_entity.present?
                               route.route_entity
                             end

                  models = models.flatten.compact

                  operation = {
                    :notes      => notes.to_s,
                    :summary    => route.route_description || '',
                    :nickname   => route.route_nickname || (route.route_method + route.route_path.gsub(/[\/:\(\)\.]/,'-')),
                    :method     => route.route_method,
                    :parameters => parse_header_params(route.route_headers) + parse_params(route.route_params, route.route_path, route.route_method),
                    :type       => "void"
                  }
                  operation[:authorizations] = route.route_authorizations unless (route.route_authorizations.nil? || route.route_authorizations.empty?)
                  if operation[:parameters].any? { | param | param[:type] == "File" }
                    operation.merge!(:consumes => [ "multipart/form-data" ])
                  end
                  operation.merge!(:responseMessages => http_codes) unless http_codes.empty?

                  if route.route_entity
                    type = parse_entity_name(route.route_entity)
                    if route.instance_variable_get(:@options)[:is_array]
                      operation.merge!({
                        "type" => "array",
                        "items" => generate_typeref(type)
                      })
                    else
                      operation.merge!("type" => type)
                    end
                  end

                  operation
                end.compact
                apis << {
                  path: path,
                  operations: operations
                }
              end

              api_description = {
                apiVersion:     api_version,
                swaggerVersion: "1.2",
                resourcePath:   "/#{params[:name]}",
                produces:       content_types_for(target_class),
                apis:           apis
              }

              basePath                         = parse_base_path(base_path, request)
              api_description[:basePath]       = basePath        if basePath && basePath.size > 0 && root_base_path != false
              api_description[:models]         = parse_entity_models(models) unless models.empty?
              api_description[:authorizations] = authorizations  if authorizations

              api_description
            end
          end

          helpers do

            def as_markdown(description)
              description && @@markdown ? Kramdown::Document.new(strip_heredoc(description), :input => 'GFM', :enable_coderay => false).to_html : description
            end

            def parse_params(params, path, method)
              params ||= []
              params.map do |param, value|
                value[:type] = 'File' if value.is_a?(Hash) && value[:type] == 'Rack::Multipart::UploadedFile'
                items = {}

                raw_data_type = value.is_a?(Hash) ? (value[:type] || 'string').to_s : 'string'
                dataType      = data_type_from_raw_data_type(raw_data_type)
                description   = value.is_a?(Hash) ? value[:desc] || value[:description] : ''
                required      = value.is_a?(Hash) ? !!value[:required] : false
                defaultValue  = value.is_a?(Hash) ? value[:defaultValue] : nil
                is_array      = value.is_a?(Hash) ? (value[:is_array] || false) : false
                if value.is_a?(Hash) && value.key?(:param_type)
                  paramType   = value[:param_type]
                  if is_array
                    items     = {"$ref" => dataType}
                    dataType  = "array"
                  end
                else
                  paramType   = case
                                when path.include?(":#{param}")
                                  'path'
                                when %w[ POST PUT PATCH ].include?(method)
                                  if is_primitive?(dataType)
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
                  paramType:     paramType,
                  name:          name,
                  description:   as_markdown(description),
                  type:          dataType,
                  required:      required,
                  allowMultiple: is_array
                }
                parsed_params.merge!({format: "int32"}) if dataType == "integer"
                parsed_params.merge!({format: "int64"}) if dataType == "long"
                parsed_params.merge!({items: items}) if items.present?
                parsed_params.merge!({defaultValue: defaultValue}) if defaultValue

                parsed_params
              end
            end

            def content_types_for(target_class)
              content_types = (target_class.settings[:content_types] || {}).values

              if content_types.empty?
                formats       = [target_class.settings[:format], target_class.settings[:default_format]].compact.uniq
                formats       = Grape::Formatter::Base.formatters({}).keys if formats.empty?
                content_types = Grape::ContentTypes::CONTENT_TYPES.select{|content_type, mime_type| formats.include? content_type}.values
              end

              content_types.uniq
            end

            def parse_info(info)
              {
                contact:            info[:contact],
                description:        info[:description],
                license:            info[:license],
                licenseUrl:         info[:license_url],
                termsOfServiceUrl:  info[:terms_of_service_url],
                title:              info[:title]
              }.delete_if{|_, value| value.blank?}
            end

            def data_type_from_raw_data_type(raw_data_type)
              case raw_data_type
              when "Virtus::Attribute::Boolean"
                "boolean"
              when "Boolean", "Date", "Integer", "String"
                raw_data_type.downcase
              when "BigDecimal"
                "long"
              when "DateTime"
                "dateTime"
              when "Numeric"
                "double"
              else
                parse_entity_name(raw_data_type)
              end
            end

            def parse_header_params(params)
              params ||= []

              params.map do |param, value|
                dataType    = 'String'
                description = value.is_a?(Hash) ? value[:description] : ''
                required    = value.is_a?(Hash) ? !!value[:required] : false
                defaultValue = value.is_a?(Hash) ? value[:defaultValue] : nil
                paramType   = "header"

                parsed_params = {
                  paramType:    paramType,
                  name:         param,
                  description:  as_markdown(description),
                  type:         dataType,
                  required:     required
                }

                parsed_params.merge!({defaultValue: defaultValue}) if defaultValue

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

            def parse_entity_name(name)
              entity_parts = name.to_s.split('::')
              entity_parts.reject! {|p| p == "Entity" || p == "Entities"}
              entity_parts.join("::")
            end

            def parse_entity_models(models)
              result = {}
              models.each do |model|
                name       = parse_entity_name(model)
                properties = {}
                required   = []

                model.documentation.each do |property_name, property_info|
                  p = property_info.dup

                  if p.delete(:required)
                    required << property_name.to_s
                  end

                  if p.delete(:is_array)
                    p[:items] = generate_typeref(p[:type])
                    p[:type] = "array"
                  else
                    p.merge! generate_typeref(p.delete(:type))
                  end

                  # rename Grape Entity's "desc" to "description"
                  if property_description = p.delete(:desc)
                    p[:description] = property_description
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

            def is_primitive?(type)
              %w(integer long float double string byte boolean date dateTime).include? type
            end

            def generate_typeref(type)
              if is_primitive? type
                { "type" => type }
              else
                { "$ref" => type }
              end
            end

            def parse_http_codes codes
              codes ||= {}
              codes.map do |k, v|
                {
                  code: k,
                  message: v,
                  #responseModel: ...
                }
              end
            end

            def try(*args, &block)
              if args.empty? && block_given?
                yield self
              elsif respond_to?(args.first)
                public_send(*args, &block)
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
          end
        end
      end
    end
  end
end
