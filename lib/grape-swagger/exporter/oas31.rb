# frozen_string_literal: true

module GrapeSwagger
  module Exporter
    # Exports ApiModel::Spec to OpenAPI 3.1 format.
    # Extends OAS30 with 3.1-specific differences.
    class OAS31 < OAS30
      def export
        output = {}

        output[:openapi] = openapi_version

        # OAS 3.1: jsonSchemaDialect (before info)
        output[:jsonSchemaDialect] = spec.json_schema_dialect if spec.json_schema_dialect

        output[:info] = export_info
        output[:servers] = export_servers if servers.any?
        output[:tags] = export_tags if spec.tags.any?
        output[:paths] = export_paths if spec.paths.any?

        # OAS 3.1: webhooks
        output[:webhooks] = export_webhooks if spec.webhooks.any?

        output[:components] = export_components unless components_empty?
        output[:security] = spec.security unless spec.security.nil?

        # Extensions
        spec.extensions.each { |k, v| output[k] = v }

        compact_hash(output)
      end

      protected

      def openapi_version
        '3.1.0'
      end

      # OAS 3.1 uses type array for nullable instead of nullable keyword
      def nullable_keyword?
        false
      end

      def export_license
        license = spec.info.license.dup

        # OAS 3.1 supports identifier OR url (not both)
        # If identifier is present, prefer it over url
        license.delete(:url) if license[:identifier]

        license
      end

      def export_webhooks
        spec.webhooks.transform_values do |path_item|
          export_path_item(path_item)
        end
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

        # OAS 3.1: $schema keyword for root schemas in components
        output[:$schema] = schema.json_schema if schema.respond_to?(:json_schema) && schema.json_schema

        output[:type] = schema.type if schema.type
        output[:format] = schema.format if schema.format
        output[:description] = schema.description if schema.description
        output[:enum] = schema.enum if schema.enum&.any?
        output[:default] = schema.default unless schema.default.nil?
        output[:example] = schema.example unless schema.example.nil?

        # OAS 3.1: contentMediaType and contentEncoding for binary data
        if schema.respond_to?(:content_media_type) && schema.content_media_type
          output[:contentMediaType] = schema.content_media_type
        end
        if schema.respond_to?(:content_encoding) && schema.content_encoding
          output[:contentEncoding] = schema.content_encoding
        end

        # Nullable handling - OAS 3.1 uses type array
        output[:type] = [output[:type], 'null'] if schema.nullable && output[:type]

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
          output[:properties] = schema.properties.transform_values do |prop_schema|
            export_schema(prop_schema)
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
    end
  end
end
