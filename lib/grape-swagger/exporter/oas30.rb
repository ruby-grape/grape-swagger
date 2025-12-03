# frozen_string_literal: true

module GrapeSwagger
  module Exporter
    # Exports ApiModel::Spec to OpenAPI 3.0 format.
    class OAS30 < Base
      def export
        output = {}

        output[:openapi] = openapi_version
        output[:info] = export_info
        output[:servers] = export_servers if servers.any?
        output[:tags] = export_tags if spec.tags.any?
        output[:paths] = export_paths if spec.paths.any?
        output[:components] = export_components unless components_empty?
        output[:security] = spec.security unless spec.security.nil?

        # Extensions
        spec.extensions.each { |k, v| output[k] = v }

        compact_hash(output)
      end

      protected

      def openapi_version
        '3.0.3'
      end

      def nullable_keyword?
        true
      end

      def servers
        return spec.servers if spec.servers.any?
        return [] unless spec.host

        # Build servers from Swagger 2.0 host/basePath/schemes
        schemes = spec.schemes.presence || ['https']
        schemes.map do |scheme|
          ApiModel::Server.from_swagger2(
            host: spec.host,
            base_path: spec.base_path,
            scheme: scheme
          )
        end
      end

      def components_empty?
        spec.components.schemas.empty? && spec.components.security_schemes.empty?
      end

      private

      def export_info
        info = {}
        info[:title] = spec.info.title || 'API title'
        info[:description] = spec.info.description if spec.info.description
        info[:termsOfService] = spec.info.terms_of_service if spec.info.terms_of_service
        info[:version] = spec.info.version || '1.0'

        info[:contact] = spec.info.contact if spec.info.contact
        info[:license] = export_license if spec.info.license

        spec.info.extensions.each { |k, v| info[k] = v }

        info
      end

      def export_license
        license = spec.info.license.dup
        # OAS 3.0 doesn't support identifier, only url
        license.delete(:identifier)
        license
      end

      def export_servers
        servers.map do |server|
          output = { url: server.url }
          output[:description] = server.description if server.description
          output[:variables] = server.variables.transform_values(&:to_h) if server.variables&.any?
          output
        end
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

        output[:summary] = path_item.summary if path_item.summary
        output[:description] = path_item.description if path_item.description
        output[:servers] = path_item.servers.map(&:to_h) if path_item.servers&.any?
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
        output[:deprecated] = operation.deprecated if operation.deprecated
        output[:security] = operation.security unless operation.security.nil?

        # Parameters (OAS3 style with schema wrapper)
        params = operation.parameters.map { |p| export_parameter(p) }
        output[:parameters] = params if params.any?

        # Request body (OAS3 specific)
        output[:requestBody] = export_request_body(operation.request_body) if operation.request_body

        # Responses
        output[:responses] = export_responses(operation.responses) if operation.responses.any?

        operation.extensions.each { |k, v| output[k] = v }

        output
      end

      def export_parameter(param)
        output = {}

        output[:name] = param.name
        output[:in] = param.location
        output[:description] = param.description if param.description
        output[:required] = param.required

        # OAS3 requires schema wrapper
        output[:schema] = export_parameter_schema(param)

        # Style and explode (OAS3)
        if param.collection_format
          output[:style] = param.style_from_collection_format
          output[:explode] = param.explode_from_collection_format
        elsif param.style
          output[:style] = param.style
          output[:explode] = param.explode unless param.explode.nil?
        end

        output[:deprecated] = param.deprecated if param.deprecated
        output[:allowEmptyValue] = param.allow_empty_value if param.allow_empty_value
        output[:example] = param.example unless param.example.nil?
        output[:examples] = param.examples if param.examples&.any?

        param.extensions.each { |k, v| output[k] = v }

        output
      end

      def export_parameter_schema(param)
        if param.schema
          export_schema(param.schema)
        else
          # Build schema from inline properties
          schema = {}
          schema[:type] = param.type if param.type
          schema[:format] = param.format if param.format
          schema[:items] = export_schema(param.items) if param.items
          schema[:default] = param.default unless param.default.nil?
          schema[:enum] = param.enum if param.enum&.any?
          schema[:minimum] = param.minimum if param.minimum
          schema[:maximum] = param.maximum if param.maximum
          schema[:minLength] = param.min_length if param.min_length
          schema[:maxLength] = param.max_length if param.max_length
          schema[:pattern] = param.pattern if param.pattern
          schema
        end
      end

      def export_request_body(request_body)
        return nil unless request_body

        output = {}
        output[:description] = request_body.description if request_body.description
        output[:required] = request_body.required unless request_body.required.nil?
        output[:content] = export_content(request_body.media_types) if request_body.media_types.any?

        request_body.extensions.each { |k, v| output[k] = v }

        output
      end

      def export_content(media_types)
        media_types.each_with_object({}) do |mt, result|
          content = {}
          content[:schema] = export_schema(mt.schema) if mt.schema
          content[:example] = mt.example unless mt.example.nil?
          content[:examples] = mt.examples if mt.examples&.any?
          content[:encoding] = mt.encoding if mt.encoding&.any?
          mt.extensions.each { |k, v| content[k] = v }
          result[mt.mime_type] = content
        end
      end

      def export_responses(responses)
        responses.each_with_object({}) do |(code, response), result|
          result[code.to_s] = export_response(response)
        end
      end

      def export_response(response)
        output = { description: response.description || '' }

        # Content with schema (OAS3 style)
        if response.media_types.any?
          output[:content] = export_content(response.media_types)
        elsif response.schema
          # Convert schema to content
          output[:content] = {
            'application/json' => { schema: export_schema(response.schema) }
          }
        end

        if response.headers.any?
          output[:headers] = response.headers.each_with_object({}) do |(name, header), h|
            h[name] = export_header(header)
          end
        end

        output[:links] = response.links if response.links&.any?

        response.extensions.each { |k, v| output[k] = v }

        output
      end

      def export_header(header)
        output = {}
        output[:description] = header.description if header.description
        output[:required] = header.required if header.required
        output[:deprecated] = header.deprecated if header.deprecated

        # OAS3 requires schema wrapper for headers
        if header.schema
          output[:schema] = export_schema(header.schema)
        else
          schema = {}
          schema[:type] = header.type if header.type
          schema[:format] = header.format if header.format
          output[:schema] = schema unless schema.empty?
        end

        header.extensions.each { |k, v| output[k] = v }

        output
      end

      def export_components
        output = {}

        if spec.components.schemas.any?
          output[:schemas] = spec.components.schemas.each_with_object({}) do |(name, schema), result|
            result[name] = export_schema(schema)
          end
        end

        if spec.components.security_schemes.any?
          output[:securitySchemes] = spec.components.security_schemes.each_with_object({}) do |(name, scheme), result|
            result[name] = export_security_scheme(scheme)
          end
        end

        output
      end

      def export_schema(schema)
        return nil unless schema

        # Handle reference
        if schema.respond_to?(:canonical_name) && schema.canonical_name && !schema.type
          return { '$ref' => "#/components/schemas/#{schema.canonical_name}" }
        end

        # Handle hash input
        return export_hash_schema(schema) if schema.is_a?(Hash)

        output = {}

        # Handle null type - OAS 3.0 doesn't support type: null directly
        if schema.type == 'null'
          # In OAS 3.0, we represent a null-only type as an empty object with nullable
          output[:nullable] = true if nullable_keyword?
          return output
        end

        output[:type] = schema.type if schema.type
        output[:format] = schema.format if schema.format
        output[:description] = schema.description if schema.description
        output[:enum] = schema.enum if schema.enum&.any?
        output[:default] = schema.default unless schema.default.nil?
        output[:example] = schema.example unless schema.example.nil?

        # Nullable handling
        if schema.nullable
          if nullable_keyword?
            output[:nullable] = true
          else
            # OAS 3.1 uses type array
            output[:type] = [output[:type], 'null'] if output[:type]
          end
        end

        output[:readOnly] = schema.read_only if schema.read_only
        output[:writeOnly] = schema.write_only if schema.write_only
        output[:deprecated] = schema.deprecated if schema.deprecated

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
        output[:oneOf] = schema.one_of.map { |s| export_schema(s) } if schema.one_of&.any?
        output[:anyOf] = schema.any_of.map { |s| export_schema(s) } if schema.any_of&.any?
        output[:not] = export_schema(schema.not) if schema.not
        output[:discriminator] = schema.discriminator if schema.discriminator

        # Extensions
        schema.extensions&.each { |k, v| output[k] = v }

        output
      end

      def export_hash_schema(schema)
        # Handle raw hash input
        if schema['$ref'] || schema[:$ref]
          ref = schema['$ref'] || schema[:$ref]
          # Convert Swagger 2.0 refs to OAS3
          ref = ref.gsub('#/definitions/', '#/components/schemas/')
          return { '$ref' => ref }
        end

        schema
      end

      def export_security_scheme(scheme)
        output = { type: scheme.type }
        output[:description] = scheme.description if scheme.description

        case scheme.type
        when 'apiKey'
          output[:name] = scheme.name
          output[:in] = scheme.location
        when 'http'
          output[:scheme] = scheme.scheme
          output[:bearerFormat] = scheme.bearer_format if scheme.bearer_format
        when 'oauth2'
          output[:flows] = scheme.flows if scheme.flows
        when 'openIdConnect'
          output[:openIdConnectUrl] = scheme.open_id_connect_url
        end

        scheme.extensions.each { |k, v| output[k] = v }

        output
      end
    end
  end
end
