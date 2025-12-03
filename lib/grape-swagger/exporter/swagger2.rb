# frozen_string_literal: true

module GrapeSwagger
  module Exporter
    # Exports ApiModel::Spec to Swagger 2.0 format.
    # This exporter produces output compatible with the original grape-swagger format.
    class Swagger2 < Base
      def export
        output = {}

        output[:swagger] = '2.0'
        output[:info] = export_info
        output[:host] = spec.host if spec.host
        output[:basePath] = spec.base_path if spec.base_path
        output[:schemes] = spec.schemes if spec.schemes&.any?
        output[:produces] = spec.produces if spec.produces&.any?
        output[:consumes] = spec.consumes if spec.consumes&.any?
        output[:tags] = export_tags if spec.tags.any?
        output[:paths] = export_paths if spec.paths.any?
        output[:definitions] = export_definitions if spec.components.schemas.any?
        output[:securityDefinitions] = export_security_definitions if spec.components.security_schemes.any?
        output[:security] = spec.security if spec.security&.any?

        # Extensions
        spec.extensions.each { |k, v| output[k] = v }

        compact_hash(output)
      end

      private

      def export_info
        info = {}
        info[:title] = spec.info.title || 'API title'
        info[:description] = spec.info.description if spec.info.description
        info[:termsOfService] = spec.info.terms_of_service if spec.info.terms_of_service
        info[:version] = spec.info.version || '1.0'

        if spec.info.contact
          contact = spec.info.contact.dup
          contact.delete(:identifier) # Not in Swagger 2.0
          info[:contact] = contact unless contact.empty?
        end

        if spec.info.license
          license = spec.info.license.dup
          license.delete(:identifier) # Not in Swagger 2.0
          info[:license] = license unless license.empty?
        end

        spec.info.extensions.each { |k, v| info[k] = v }

        info
      end

      def export_tags
        spec.tags.map do |tag|
          tag_hash = { name: tag.name }
          tag_hash[:description] = tag.description if tag.description
          tag_hash[:externalDocs] = tag.external_docs.to_h if tag.external_docs
          tag.extensions.each { |k, v| tag_hash[k] = v }
          tag_hash
        end
      end

      def export_paths
        spec.paths.each_with_object({}) do |(path, path_item), result|
          result[path] = export_path_item(path_item)
        end
      end

      def export_path_item(path_item)
        output = {}

        output[:parameters] = path_item.parameters.map { |p| export_parameter(p) } if path_item.parameters.any?

        path_item.operations.each do |method, operation|
          output[method.to_sym] = export_operation(operation)
        end

        path_item.extensions.each { |k, v| output[k] = v }

        output
      end

      def export_operation(operation)
        output = {}

        output[:operationId] = operation.operation_id if operation.operation_id
        output[:summary] = operation.summary if operation.summary
        output[:description] = operation.description if operation.description
        output[:tags] = operation.tags if operation.tags&.any?
        output[:produces] = operation.produces if operation.produces&.any?
        output[:consumes] = operation.consumes if operation.consumes&.any?
        output[:deprecated] = operation.deprecated if operation.deprecated
        output[:security] = operation.security if operation.security&.any?

        # Parameters (including body from request_body)
        params = export_operation_parameters(operation)
        output[:parameters] = params if params.any?

        # Responses
        output[:responses] = export_responses(operation.responses) if operation.responses.any?

        operation.extensions.each { |k, v| output[k] = v }

        output
      end

      def export_operation_parameters(operation)
        params = operation.parameters.map { |p| export_parameter(p) }

        # Convert request body back to body parameter
        if operation.request_body
          params << export_request_body_as_parameter(operation.request_body)
        end

        params.compact
      end

      def export_parameter(param)
        output = {}

        output[:name] = param.name
        output[:in] = param.location
        output[:description] = param.description if param.description
        output[:required] = param.required

        # Inline type properties for Swagger 2.0
        if param.type
          output[:type] = param.type
          output[:format] = param.format if param.format
          output[:items] = export_items(param.items) if param.items
          output[:collectionFormat] = param.collection_format if param.collection_format
          output[:default] = param.default unless param.default.nil?
          output[:enum] = param.enum if param.enum&.any?
          output[:minimum] = param.minimum if param.minimum
          output[:maximum] = param.maximum if param.maximum
          output[:minLength] = param.min_length if param.min_length
          output[:maxLength] = param.max_length if param.max_length
          output[:pattern] = param.pattern if param.pattern
        elsif param.schema
          # If only schema is set, extract inline properties
          schema = param.schema
          output[:type] = schema.type if schema.type
          output[:format] = schema.format if schema.format
          output[:items] = export_schema(schema.items) if schema.items
          output[:default] = schema.default unless schema.default.nil?
          output[:enum] = schema.enum if schema.enum&.any?
          output[:minimum] = schema.minimum if schema.minimum
          output[:maximum] = schema.maximum if schema.maximum
          output[:minLength] = schema.min_length if schema.min_length
          output[:maxLength] = schema.max_length if schema.max_length
          output[:pattern] = schema.pattern if schema.pattern
        end

        param.extensions.each { |k, v| output[k] = v }

        output
      end

      def export_request_body_as_parameter(request_body)
        return nil unless request_body.media_types.any?

        primary = request_body.media_types.first
        return nil unless primary&.schema

        output = {
          name: 'body',
          in: 'body',
          required: request_body.required
        }
        output[:description] = request_body.description if request_body.description
        output[:schema] = export_schema(primary.schema)

        output
      end

      def export_responses(responses)
        responses.each_with_object({}) do |(code, response), result|
          result[code.to_s] = export_response(response)
        end
      end

      def export_response(response)
        output = { description: response.description || '' }

        # Use stored schema or extract from media types
        schema = response.schema
        schema ||= response.media_types.first&.schema if response.media_types.any?

        output[:schema] = export_schema(schema) if schema

        if response.headers.any?
          output[:headers] = response.headers.each_with_object({}) do |(name, header), h|
            h[name] = export_header(header)
          end
        end

        output[:examples] = response.examples if response.examples&.any?

        response.extensions.each { |k, v| output[k] = v }

        output
      end

      def export_header(header)
        output = {}
        output[:description] = header.description if header.description
        output[:type] = header.type || header.schema&.type
        output[:format] = header.format || header.schema&.format
        header.extensions.each { |k, v| output[k] = v }
        output
      end

      def export_definitions
        spec.components.schemas.each_with_object({}) do |(name, schema), result|
          result[name] = export_schema(schema)
        end
      end

      def export_schema(schema)
        return nil unless schema

        # Handle reference
        if schema.canonical_name && !schema.type
          return { '$ref' => "#/definitions/#{schema.canonical_name}" }
        end

        output = {}
        output[:type] = schema.type if schema.type
        output[:format] = schema.format if schema.format
        output[:description] = schema.description if schema.description
        output[:enum] = schema.enum if schema.enum&.any?
        output[:default] = schema.default unless schema.default.nil?
        output[:example] = schema.example unless schema.example.nil?

        # Numeric constraints
        output[:minimum] = schema.minimum if schema.minimum
        output[:maximum] = schema.maximum if schema.maximum
        output[:exclusiveMinimum] = schema.exclusive_minimum if schema.exclusive_minimum
        output[:exclusiveMaximum] = schema.exclusive_maximum if schema.exclusive_maximum
        output[:multipleOf] = schema.multiple_of if schema.multiple_of

        # String constraints
        output[:minLength] = schema.min_length if schema.min_length
        output[:maxLength] = schema.max_length if schema.max_length
        output[:pattern] = schema.pattern if schema.pattern

        # Array
        output[:items] = export_schema(schema.items) if schema.items
        output[:minItems] = schema.min_items if schema.min_items
        output[:maxItems] = schema.max_items if schema.max_items

        # Object
        if schema.properties.any?
          output[:properties] = schema.properties.each_with_object({}) do |(prop_name, prop_schema), props|
            props[prop_name] = export_schema(prop_schema)
          end
        end
        output[:required] = schema.required if schema.required.any?
        output[:additionalProperties] = schema.additional_properties unless schema.additional_properties.nil?

        # Composition
        output[:allOf] = schema.all_of.map { |s| export_schema(s) } if schema.all_of&.any?
        output[:discriminator] = schema.discriminator if schema.discriminator

        # Extensions
        schema.extensions.each { |k, v| output[k] = v } if schema.extensions

        output
      end

      def export_items(items)
        return items if items.is_a?(Hash)
        return export_schema(items) if items.is_a?(ApiModel::Schema)

        items
      end

      def export_security_definitions
        spec.components.security_schemes.each_with_object({}) do |(name, scheme), result|
          result[name] = export_security_scheme(scheme)
        end
      end

      def export_security_scheme(scheme)
        output = {}

        # Convert OAS3 types back to Swagger 2.0
        case scheme.type
        when 'http'
          if scheme.scheme == 'basic'
            output[:type] = 'basic'
          else
            output[:type] = 'apiKey'
            output[:name] = scheme.name || 'Authorization'
            output[:in] = 'header'
          end
        when 'apiKey'
          output[:type] = 'apiKey'
          output[:name] = scheme.name
          output[:in] = scheme.location
        when 'oauth2'
          output[:type] = 'oauth2'
          if scheme.flows
            flow_type, flow = scheme.flows.first
            output[:flow] = convert_oauth_flow_type(flow_type)
            output[:authorizationUrl] = flow[:authorizationUrl] if flow[:authorizationUrl]
            output[:tokenUrl] = flow[:tokenUrl] if flow[:tokenUrl]
            output[:scopes] = flow[:scopes] if flow[:scopes]
          end
        else
          output[:type] = scheme.type
        end

        output[:description] = scheme.description if scheme.description
        scheme.extensions.each { |k, v| output[k] = v }

        output
      end

      def convert_oauth_flow_type(oas3_flow)
        case oas3_flow.to_s
        when 'implicit' then 'implicit'
        when 'password' then 'password'
        when 'clientCredentials' then 'application'
        when 'authorizationCode' then 'accessCode'
        else oas3_flow.to_s
        end
      end
    end
  end
end
