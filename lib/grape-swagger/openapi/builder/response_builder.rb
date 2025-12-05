# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds OpenAPI::Response objects from route response definitions.
      class ResponseBuilder
        DEFAULT_CONTENT_TYPES = ['application/json'].freeze

        def initialize(schema_builder, definitions = {})
          @schema_builder = schema_builder
          @definitions = definitions
        end

        # Build a response from a response hash
        def build(status_code, response_hash, content_types: DEFAULT_CONTENT_TYPES)
          response = OpenAPI::Response.new
          response.status_code = status_code.to_s
          response.description = response_hash[:description] || ''

          # Handle schema
          if response_hash[:schema]
            schema = build_schema_from_hash(response_hash[:schema])
            add_content_to_response(response, schema, content_types)
          end

          # Handle headers
          response_hash[:headers]&.each do |name, header_def|
            response.add_header(
              name,
              schema: @schema_builder.build_from_param(header_def),
              description: header_def[:description]
            )
          end

          # Handle examples
          response.examples = response_hash[:examples] if response_hash[:examples]

          # Copy extension fields
          response_hash.each do |key, value|
            response.extensions[key] = value if key.to_s.start_with?('x-')
          end

          response
        end

        # Build all responses from a hash of status_code => response_hash
        def build_all(responses_hash, content_types: DEFAULT_CONTENT_TYPES)
          responses_hash.each_with_object({}) do |(code, resp), hash|
            hash[code.to_s] = build(code, resp, content_types: content_types)
          end
        end

        private

        def build_schema_from_hash(schema_hash)
          if schema_hash['$ref'] || schema_hash[:$ref]
            ref = schema_hash['$ref'] || schema_hash[:$ref]
            model_name = ref.split('/').last
            OpenAPI::Schema.new(canonical_name: model_name)
          elsif schema_hash[:type] == 'array' && schema_hash[:items]
            schema = OpenAPI::Schema.new(type: 'array')
            schema.items = build_schema_from_hash(schema_hash[:items])
            schema
          elsif schema_hash[:type] == 'file'
            OpenAPI::Schema.new(type: 'string', format: 'binary')
          else
            @schema_builder.build_from_param(schema_hash)
          end
        end

        def add_content_to_response(response, schema, content_types)
          # For file responses, use octet-stream
          if schema.type == 'string' && schema.format == 'binary'
            response.add_media_type('application/octet-stream', schema: schema)
          else
            content_types.each do |content_type|
              response.add_media_type(content_type, schema: schema)
            end
          end

          # Also store schema for Swagger 2.0 compat
          response.schema = schema
        end
      end
    end
  end
end
