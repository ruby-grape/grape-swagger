# frozen_string_literal: true

require_relative 'parameter_builder'
require_relative 'request_body_builder'
require_relative 'response_builder'

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds OpenAPI::Document directly from Grape routes without intermediate Swagger 2.0 hash.
      # This preserves all Grape options that would otherwise be lost in conversion (e.g., allow_blank → nullable).
      #
      # Architecture:
      #   Grape Routes → FromRoutes → OpenAPI Model → Exporter → OAS3 Output
      #
      # This is the active path for OAS3 generation. The Swagger 2.0 path remains unchanged:
      #   Grape Routes → endpoint.rb → Swagger Hash
      class FromRoutes
        include ParameterBuilder
        include RequestBodyBuilder
        include ResponseBuilder

        attr_reader :spec, :definitions, :options

        def initialize(endpoint, target_class, request, options)
          @endpoint = endpoint
          @target_class = target_class
          @request = request
          @options = options
          @definitions = {}
          @spec = OpenAPI::Document.new
          @schema_builder = SchemaBuilder.new(@definitions)
        end

        def build(namespace_routes)
          # Initialize @definitions on endpoint so model parsers can use it
          @endpoint.instance_variable_set(:@definitions, @definitions)

          build_info
          build_servers
          build_content_types
          build_security_definitions
          build_paths(namespace_routes)
          build_tags
          build_extensions

          @spec
        end

        private

        # ==================== Info ====================

        def build_info
          info_options = options[:info] || {}
          @spec.info = OpenAPI::Info.new(
            title: info_options[:title] || 'API title',
            description: info_options[:description],
            terms_of_service: info_options[:terms_of_service_url],
            version: options[:doc_version] || info_options[:version] || '1.0',
            contact_name: info_options[:contact_name],
            contact_email: info_options[:contact_email],
            contact_url: info_options[:contact_url]
          )

          build_license(info_options)
          copy_info_extensions(info_options)
        end

        def build_license(info_options)
          license = info_options[:license]
          return unless license

          if license.is_a?(Hash)
            @spec.info.license_name = license[:name]
            @spec.info.license_url = license[:url] || info_options[:license_url]
            @spec.info.license_identifier = license[:identifier]
          else
            @spec.info.license_name = license
            @spec.info.license_url = info_options[:license_url]
          end
        end

        def copy_info_extensions(info_options)
          info_options.each do |key, value|
            @spec.info.extensions[key] = value if key.to_s.start_with?('x-')
          end
        end

        # ==================== Servers ====================

        def build_servers
          host = GrapeSwagger::DocMethods::OptionalObject.build(:host, options, @request)
          base_path = GrapeSwagger::DocMethods::OptionalObject.build(:base_path, options, @request)
          schemes = normalize_schemes(options[:schemes])

          # Store for Swagger 2.0 compatibility
          @spec.host = host
          @spec.base_path = base_path
          @spec.schemes = schemes

          # Build OAS3 servers
          return unless host

          (schemes.presence || ['https']).each do |scheme|
            @spec.add_server(
              OpenAPI::Server.from_swagger2(host: host, base_path: base_path, scheme: scheme)
            )
          end
        end

        def normalize_schemes(schemes)
          return [] unless schemes

          schemes.is_a?(String) ? [schemes] : Array(schemes)
        end

        # ==================== Content Types ====================

        def build_content_types
          @spec.produces = options[:produces] || content_types_for_target
          @spec.consumes = options[:consumes]
        end

        def content_types_for_target
          @endpoint.content_types_for(@target_class)
        end

        # ==================== Security ====================

        def build_security_definitions
          return unless options[:security_definitions]

          options[:security_definitions].each do |name, definition|
            scheme = build_security_scheme(definition)
            @spec.components.add_security_scheme(name, scheme)
          end

          @spec.security = options[:security] if options[:security]
        end

        def build_security_scheme(definition)
          scheme = OpenAPI::SecurityScheme.new
          scheme.type = convert_security_type(definition[:type])
          scheme.description = definition[:description]
          scheme.name = definition[:name]
          scheme.location = definition[:in]

          case definition[:type]
          when 'basic'
            scheme.type = 'http'
            scheme.scheme = 'basic'
          when 'oauth2'
            scheme.flows = build_oauth_flows(definition)
          end

          scheme
        end

        def convert_security_type(type)
          case type
          when 'basic' then 'http'
          else type
          end
        end

        def build_oauth_flows(definition)
          flow_type = case definition[:flow]
                      when 'implicit' then 'implicit'
                      when 'password' then 'password'
                      when 'application' then 'clientCredentials'
                      when 'accessCode' then 'authorizationCode'
                      else definition[:flow]
                      end

          {
            flow_type => {
              authorizationUrl: definition[:authorizationUrl],
              tokenUrl: definition[:tokenUrl],
              scopes: definition[:scopes]
            }.compact
          }
        end

        # ==================== Paths ====================

        def build_paths(namespace_routes)
          # Add models from options
          add_definitions_from(options[:models])

          namespace_routes.each_value do |routes|
            routes.each do |route|
              next if hidden?(route)

              build_path_item(route)
            end
          end
        end

        def add_definitions_from(models)
          return unless models

          models.each { |model| expose_params_from_model(model) }
        end

        def build_path_item(route)
          @current_item, path = GrapeSwagger::DocMethods::PathString.build(route, options)
          @current_entity = route.entity || route.options[:success]

          path_item = @spec.paths[path] || OpenAPI::PathItem.new(path: path)
          operation = build_operation(route, path)
          path_item.add_operation(route.request_method.downcase.to_sym, operation)

          @spec.add_path(path, path_item)

          # Handle path-level extensions
          add_path_extensions(path_item, route)
        end

        def add_path_extensions(path_item, route)
          x_path = route.settings[:x_path]
          return unless x_path

          x_path.each do |key, value|
            path_item.extensions["x-#{key}"] = value
          end
        end

        # ==================== Operations ====================

        def build_operation(route, path)
          operation = OpenAPI::Operation.new
          operation.operation_id = GrapeSwagger::DocMethods::OperationId.build(route, path)
          operation.summary = build_summary(route)
          operation.description = build_description(route)
          operation.deprecated = route.options[:deprecated] if route.options.key?(:deprecated)
          operation.tags = route.options.fetch(:tags, build_tags_for_route(route, path))
          operation.security = route.options[:security] if route.options.key?(:security)
          operation.produces = build_produces(route)
          operation.consumes = build_consumes(route)

          build_operation_parameters(operation, route, path)
          build_operation_responses(operation, route)
          add_operation_extensions(operation, route)

          operation
        end

        def build_summary(route)
          summary = route.options[:desc] if route.options.key?(:desc)
          summary = route.description if route.description.present? && route.options.key?(:detail)
          summary = route.options[:summary] if route.options.key?(:summary)
          summary
        end

        def build_description(route)
          description = route.description if route.description.present?
          description = route.options[:detail] if route.options.key?(:detail)
          description
        end

        def build_produces(route)
          return ['application/octet-stream'] if file_response?(route.options[:success]) &&
                                                 !route.options[:produces].present?

          format = options[:produces] || options[:format]
          mime_types = GrapeSwagger::DocMethods::ProducesConsumes.call(format)

          route_mime_types = %i[formats content_types produces].filter_map do |producer|
            possible = route.options[producer]
            GrapeSwagger::DocMethods::ProducesConsumes.call(possible) if possible.present?
          end.flatten.uniq

          route_mime_types.presence || mime_types
        end

        def build_consumes(route)
          return unless %i[post put patch].include?(route.request_method.downcase.to_sym)

          format = options[:consumes] || options[:format]
          GrapeSwagger::DocMethods::ProducesConsumes.call(
            route.settings.dig(:description, :consumes) || format
          )
        end

        def build_tags_for_route(route, path)
          version = GrapeSwagger::DocMethods::Version.get(route)
          version = Array(version)
          prefix = route.prefix.to_s.split('/').reject(&:empty?)

          Array(
            path.split('{')[0].split('/').reject(&:empty?).delete_if do |i|
              prefix.include?(i) || version.map(&:to_s).include?(i)
            end.first
          ).presence
        end

        def add_operation_extensions(operation, route)
          x_operation = route.settings[:x_operation]
          return unless x_operation

          x_operation.each do |key, value|
            operation.extensions["x-#{key}"] = value
          end
        end

        # ==================== Tags ====================

        def build_tags
          # Collect unique tags from all operations
          all_tags = Set.new
          @spec.paths.each_value do |path_item|
            # operations returns array of [method, operation] pairs, not a hash
            path_item.operations.each do |_method, operation| # rubocop:disable Style/HashEachMethods
              next unless operation&.tags

              operation.tags.each { |tag| all_tags << tag }
            end
          end

          # Build tag objects with descriptions
          all_tags.each do |tag_name|
            tag = OpenAPI::Tag.new(
              name: tag_name,
              description: "Operations about #{tag_name.to_s.pluralize}"
            )
            @spec.add_tag(tag)
          end

          # Merge with user-provided tags
          return unless options[:tags]

          user_tag_names = options[:tags].map { |t| t[:name] }
          @spec.tags.reject! { |t| user_tag_names.include?(t.name) }

          options[:tags].each do |tag_hash|
            tag = OpenAPI::Tag.new(
              name: tag_hash[:name],
              description: tag_hash[:description]
            )
            @spec.add_tag(tag)
          end
        end

        # ==================== Extensions ====================

        def build_extensions
          GrapeSwagger::DocMethods::Extensions.add_extensions_to_root(options, @spec.extensions)
        end

        # ==================== Helpers ====================

        def hidden?(route)
          route_hidden = route.settings.try(:[], :swagger).try(:[], :hidden)
          route_hidden = route.options[:hidden] if route.options.key?(:hidden)
          return route_hidden unless route_hidden.is_a?(Proc)

          return route_hidden.call unless options[:token_owner]

          token_owner = GrapeSwagger::TokenOwnerResolver.resolve(@endpoint, options[:token_owner])
          GrapeSwagger::TokenOwnerResolver.evaluate_proc(route_hidden, token_owner)
        end

        def hidden_parameter?(param_options)
          return false if param_options[:required]

          doc = param_options[:documentation] || {}
          hidden = doc[:hidden]

          if hidden.is_a?(Proc)
            hidden.call
          else
            hidden
          end
        end

        def file_response?(value)
          value.to_s.casecmp('file').zero?
        end

        def expose_params_from_model(model)
          # Handle array format (from failure codes) or empty/nil values
          return nil if model.nil? || model.is_a?(Array)
          return nil if model.is_a?(String) && model.strip.empty?

          model = model.constantize if model.is_a?(String)
          model_name = GrapeSwagger::DocMethods::DataType.parse_entity_name(model)

          return model_name if @definitions.key?(model_name)

          @definitions[model_name] = nil

          parser = GrapeSwagger.model_parsers.find(model)
          raise GrapeSwagger::Errors::UnregisteredParser, "No parser registered for #{model_name}." unless parser

          parsed_response = parser.new(model, self).call

          if parsed_response.is_a?(OpenAPI::Schema)
            schema = parsed_response
            schema.canonical_name ||= model_name
            @definitions[model_name] = schema.to_h
            @spec.components.add_schema(model_name, schema)
            return model_name
          end

          definition = GrapeSwagger::DocMethods::BuildModelDefinition.parse_params_from_model(
            parsed_response, model, model_name
          )

          @definitions[model_name] = definition

          # Recursively expose nested models referenced by $ref
          expose_nested_refs(definition)

          # Convert definition to schema and add to components
          schema = @schema_builder.build_from_definition(definition)
          schema.canonical_name = model_name
          @spec.components.add_schema(model_name, schema)

          model_name
        end

        # Recursively find and expose $ref references in a definition
        def expose_nested_refs(obj)
          return unless obj.is_a?(Hash)

          # Check for $ref at current level
          if obj['$ref'] || obj[:$ref]
            ref = obj['$ref'] || obj[:$ref]
            ref_name = ref.split('/').last
            # Only expose if not already defined
            unless @definitions.key?(ref_name)
              # Try to find the model class and expose it
              begin
                klass = Object.const_get(ref_name)
                expose_params_from_model(klass) if GrapeSwagger.model_parsers.find(klass)
              rescue NameError
                # Class not found - that's ok, might be defined elsewhere
              end
            end
          end

          # Recursively check nested structures
          obj.each_value do |value|
            if value.is_a?(Hash)
              expose_nested_refs(value)
            elsif value.is_a?(Array)
              value.each { |item| expose_nested_refs(item) if item.is_a?(Hash) }
            end
          end
        end
      end
    end
  end
end
