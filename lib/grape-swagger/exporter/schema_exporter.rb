# frozen_string_literal: true

require_relative 'schema_fields'

module GrapeSwagger
  module Exporter
    # Shared schema export methods for OAS 3.x exporters
    module SchemaExporter
      include SchemaFields

      def export_schema(schema)
        return nil unless schema
        return export_ref_schema(schema) if schema_is_ref?(schema)
        return export_hash_schema(schema) if schema.is_a?(Hash)

        build_schema_output(schema)
      end

      # The body of a named component. Unlike a usage site, a component whose only content is a
      # canonical name (or whose fields are enum/additionalProperties) must not become a $ref to
      # itself, so the body is built directly; only an alias to a different component stays a $ref.
      def export_component_schema(name, schema)
        return export_schema(schema) if schema.is_a?(Hash)
        return export_schema(schema) if schema_is_ref?(schema) && schema.canonical_name.to_s != name.to_s

        build_schema_output(schema)
      end

      private

      # A reference site carries a canonical name and nothing that defines a shape of its own.
      def schema_is_ref?(schema)
        schema.respond_to?(:canonical_name) && schema.canonical_name && !schema.type &&
          schema.properties.empty? && !schema.items && !composition?(schema)
      end

      def composition?(schema)
        [schema.all_of, schema.one_of, schema.any_of].any? { |s| s&.any? }
      end

      # A bare $ref stays bare. Siblings (description, nullable, ...) are not allowed beside
      # $ref in OAS 3.0 and ignored in older 3.1 tooling, so the $ref moves into allOf, or into a
      # null union when the reference is nullable.
      def export_ref_schema(schema)
        ref = { '$ref' => "#/components/schemas/#{schema.canonical_name}" }
        output = build_schema_output(schema)
        output.delete(:nullable)
        return ref if output.empty? && !schema.nullable

        if schema.nullable
          output.merge(anyOf: [ref, null_schema])
        else
          output.merge(allOf: [ref])
        end
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
        add_schema_nullable_composition(output, schema)
        output
      end

      # `nullable: true` has no effect next to a composition keyword (OAS 3.0 needs a sibling type,
      # 3.1 a null type), so the composition becomes one alternative of a union with null.
      def add_schema_nullable_composition(output, schema)
        keys = %i[allOf oneOf anyOf].select { |k| output.key?(k) }
        return unless schema.nullable && keys.any?

        output.delete(:nullable) unless output[:type]
        branch = keys.to_h { |k| [k, output.delete(k)] }
        branch[:discriminator] = output.delete(:discriminator) if output.key?(:discriminator)
        output[:anyOf] = [branch, null_schema]
      end

      def null_schema
        nullable_keyword? ? { type: 'object', nullable: true, enum: [nil] } : { type: 'null' }
      end

      # OAS 3 discriminators are objects; accept the model hash in snake_case or OAS casing.
      # The Swagger 2.0 form, a bare property name, becomes `{ propertyName: name }`.
      def export_discriminator(discriminator)
        return { propertyName: discriminator.to_s } unless discriminator.is_a?(Hash)

        name = discriminator[:property_name] || discriminator[:propertyName] ||
               discriminator['property_name'] || discriminator['propertyName']
        mapping = discriminator[:mapping] || discriminator['mapping']
        { propertyName: name, mapping: mapping.presence }.compact
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
