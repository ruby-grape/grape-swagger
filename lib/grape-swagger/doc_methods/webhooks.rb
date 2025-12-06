# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    # Builds webhook path items from configuration for OpenAPI 3.1
    module Webhooks
      class << self
        def apply(spec, webhooks_config)
          return unless webhooks_config.is_a?(Hash)

          webhooks_config.each do |name, webhook_def|
            path_item = build_path_item(webhook_def)
            spec.add_webhook(name.to_s, path_item)
          end
        end

        def build_path_item(webhook_def)
          path_item = GrapeSwagger::OpenAPI::PathItem.new

          webhook_def.each do |method, operation_def|
            next unless %i[get post put patch delete].include?(method.to_sym)

            operation = build_operation(operation_def)
            path_item.add_operation(method.to_sym, operation)
          end

          path_item
        end

        private

        def build_operation(operation_def)
          operation = GrapeSwagger::OpenAPI::Operation.new
          operation.summary = operation_def[:summary]
          operation.description = operation_def[:description]
          operation.operation_id = operation_def[:operationId] || operation_def[:operation_id]
          operation.tags = operation_def[:tags]

          operation.request_body = build_request_body(operation_def[:requestBody]) if operation_def[:requestBody]

          build_responses(operation, operation_def[:responses])

          operation
        end

        def build_responses(operation, responses_def)
          responses_def&.each do |code, response_def|
            response = GrapeSwagger::OpenAPI::Response.new
            response.description = response_def[:description] || ''
            operation.add_response(code.to_s, response)
          end
        end

        def build_request_body(request_body_def)
          request_body = GrapeSwagger::OpenAPI::RequestBody.new
          request_body.description = request_body_def[:description]
          request_body.required = request_body_def[:required]

          request_body_def[:content]&.each do |content_type, content_def|
            schema = build_schema(content_def[:schema]) if content_def[:schema]
            request_body.add_media_type(content_type.to_s, schema: schema)
          end

          request_body
        end

        def build_schema(schema_def)
          return nil unless schema_def

          if schema_def[:$ref] || schema_def['$ref']
            ref = schema_def[:$ref] || schema_def['$ref']
            schema = GrapeSwagger::OpenAPI::Schema.new
            schema.canonical_name = ref.split('/').last
            return schema
          end

          schema = GrapeSwagger::OpenAPI::Schema.new
          schema.type = schema_def[:type]
          schema.format = schema_def[:format]
          schema.description = schema_def[:description]

          schema_def[:properties]&.each do |prop_name, prop_def|
            prop_schema = build_schema(prop_def)
            schema.add_property(prop_name.to_s, prop_schema)
          end

          schema.required = Array(schema_def[:required]) if schema_def[:required]

          schema
        end
      end
    end
  end
end
