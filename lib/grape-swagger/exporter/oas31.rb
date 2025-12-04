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

      # OAS 3.1 specific schema building - extends parent with 3.1 features
      def build_schema_output(schema)
        output = {}
        add_oas31_json_schema(output, schema)
        add_schema_basic_fields(output, schema)
        add_oas31_content_fields(output, schema)
        add_schema_nullable(output, schema)
        add_schema_flags(output, schema)
        add_schema_numeric_constraints(output, schema)
        add_schema_string_constraints(output, schema)
        add_schema_array_fields(output, schema)
        add_schema_object_fields(output, schema)
        add_schema_composition(output, schema)
        add_schema_extensions(output, schema)
        output
      end

      private

      def add_oas31_json_schema(output, schema)
        return unless schema.respond_to?(:json_schema) && schema.json_schema

        output[:$schema] = schema.json_schema
      end

      def add_oas31_content_fields(output, schema)
        if schema.respond_to?(:content_media_type) && schema.content_media_type
          output[:contentMediaType] = schema.content_media_type
        end
        return unless schema.respond_to?(:content_encoding) && schema.content_encoding

        output[:contentEncoding] = schema.content_encoding
      end
    end
  end
end
