# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds OpenAPI::Parameter objects from Grape route parameters.
      class ParameterBuilder
        PARAM_LOCATIONS = {
          'path' => 'path',
          'query' => 'query',
          'header' => 'header',
          'formData' => 'formData',
          'body' => 'body'
        }.freeze

        def initialize(schema_builder)
          @schema_builder = schema_builder
        end

        # Build a parameter from parsed param hash
        def build(param_hash)
          param = OpenAPI::Parameter.new

          param.name = param_hash[:name]
          param.location = normalize_location(param_hash[:in])
          param.description = param_hash[:description]
          param.required = param.path? || param_hash[:required]
          param.deprecated = param_hash[:deprecated] if param_hash.key?(:deprecated)

          # Build schema from type info
          if param_hash[:schema]
            param.schema = @schema_builder.build_from_param(param_hash[:schema])
          else
            build_inline_schema(param, param_hash)
          end

          # Collection format (Swagger 2.0)
          param.collection_format = param_hash[:collectionFormat] if param_hash[:collectionFormat]

          # Convert to OAS3 style/explode
          if param.collection_format
            param.style = param.style_from_collection_format
            param.explode = param.explode_from_collection_format
          end

          # Copy extension fields
          param_hash.each do |key, value|
            param.extensions[key] = value if key.to_s.start_with?('x-')
          end

          param
        end

        # Build parameters from a list of param hashes
        def build_all(param_list)
          param_list.map { |p| build(p) }
        end

        # Separate body params from non-body params
        # Returns [regular_params, body_params]
        def partition_body_params(params)
          params.partition { |p| p.location != 'body' }
        end

        private

        def normalize_location(location)
          PARAM_LOCATIONS[location.to_s] || location.to_s
        end

        def build_inline_schema(param, param_hash)
          # Store inline type info for Swagger 2.0 compat
          param.type = param_hash[:type]
          param.format = param_hash[:format]
          param.items = param_hash[:items]
          param.default = param_hash[:default]
          param.enum = param_hash[:enum]
          param.minimum = param_hash[:minimum]
          param.maximum = param_hash[:maximum]
          param.min_length = param_hash[:minLength]
          param.max_length = param_hash[:maxLength]
          param.pattern = param_hash[:pattern]

          # Also build a schema object for OAS3
          param.schema = @schema_builder.build_from_param(param_hash)
        end
      end
    end
  end
end
