# frozen_string_literal: true

require_relative 'schema_fields'

module GrapeSwagger
  module Exporter
    # Shared schema export methods for OAS 3.x exporters
    module SchemaExporter
      include SchemaFields

      def export_schema(schema)
        return nil unless schema
        return schema_ref(schema) if schema_is_ref?(schema)
        return schema_ref_with_description(schema) if schema_is_ref_with_description?(schema)
        return export_hash_schema(schema) if schema.is_a?(Hash)

        build_schema_output(schema)
      end

      private

      def schema_is_ref_with_description?(schema)
        schema.respond_to?(:canonical_name) && schema.canonical_name && !schema.type && schema.description
      end

      def schema_is_ref?(schema)
        schema.respond_to?(:canonical_name) && schema.canonical_name && !schema.type && !schema.description
      end

      def schema_ref(schema)
        { '$ref' => "#/components/schemas/#{schema.canonical_name}" }
      end

      def schema_ref_with_description(schema)
        {
          'allOf' => [{ '$ref' => "#/components/schemas/#{schema.canonical_name}" }],
          'description' => schema.description
        }
      end

      def build_schema_output(schema)
        output = {}
        add_schema_basic_fields(output, schema)
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

      def export_hash_schema(schema)
        if schema['$ref'] || schema[:$ref]
          ref = schema['$ref'] || schema[:$ref]
          ref = ref.gsub('#/definitions/', '#/components/schemas/')
          return { '$ref' => ref }
        end

        schema
      end
    end
  end
end
