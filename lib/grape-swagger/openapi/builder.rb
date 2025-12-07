# frozen_string_literal: true

require_relative 'builder/concerns/info'
require_relative 'builder/concerns/servers'
require_relative 'builder/concerns/security'
require_relative 'builder/concerns/operations'
require_relative 'builder/concerns/tags'
require_relative 'builder/concerns/parameters'
require_relative 'builder/concerns/request_body'
require_relative 'builder/concerns/responses'
require_relative 'builder/concerns/schemas'

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds OpenAPI::Document directly from Grape routes.
      # This preserves all Grape options that would otherwise be lost in conversion (e.g., allow_blank → nullable).
      #
      # Architecture:
      #   Grape Routes → Builder::Spec → OpenAPI Model → Exporter → OAS3 Output
      #
      # This is the active path for OAS3 generation. The Swagger 2.0 path remains unchanged:
      #   Grape Routes → endpoint.rb → Swagger Hash
      class Spec
        include InfoBuilder
        include ServerBuilder
        include SecurityBuilder
        include OperationBuilder
        include TagBuilder
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

        # ==================== Content Types ====================

        def build_content_types
          @spec.produces = options[:produces] || content_types_for_target
          @spec.consumes = options[:consumes]
        end

        def content_types_for_target
          @endpoint.content_types_for(@target_class)
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

        def expose_nested_refs(obj)
          case obj
          when Hash
            ref = obj['$ref'] || obj[:$ref]
            expose_ref_if_needed(ref) if ref
            obj.each_value { |v| expose_nested_refs(v) }
          when Array
            obj.each { |item| expose_nested_refs(item) }
          end
        end

        def expose_ref_if_needed(ref)
          ref_name = ref.split('/').last
          return if @definitions.key?(ref_name)

          klass = Object.const_get(ref_name)
          expose_params_from_model(klass) if GrapeSwagger.model_parsers.find(klass)
        rescue NameError
          nil
        end
      end
    end
  end
end
