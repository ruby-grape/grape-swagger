# frozen_string_literal: true

module GrapeSwagger
  module Exporter
    # Schema field helper methods for OAS 3.x exporters
    module SchemaFields
      private

      def add_schema_basic_fields(output, schema)
        add_schema_type(output, schema)
        output[:format] = schema.format if schema.format
        output[:description] = schema.description if schema.description
        output[:enum] = schema.enum if schema.enum&.any?
        output[:default] = schema.default unless schema.default.nil?
        output[:example] = schema.example unless schema.example.nil?
      end

      def add_schema_type(output, schema)
        return unless schema.type

        if schema.type == 'null' && nullable_keyword?
          output[:nullable] = true
        else
          output[:type] = schema.type
        end
      end

      def add_schema_nullable(output, schema)
        return unless schema.nullable

        if nullable_keyword?
          output[:nullable] = true
        elsif output[:type]
          output[:type] = [output[:type], 'null']
        end
      end

      def add_schema_flags(output, schema)
        output[:readOnly] = schema.read_only if schema.read_only
        output[:writeOnly] = schema.write_only if schema.write_only
        output[:deprecated] = schema.deprecated if schema.deprecated
      end

      def add_schema_numeric_constraints(output, schema)
        output[:minimum] = schema.minimum if schema.minimum
        output[:maximum] = schema.maximum if schema.maximum
        output[:exclusiveMinimum] = schema.exclusive_minimum if schema.exclusive_minimum
        output[:exclusiveMaximum] = schema.exclusive_maximum if schema.exclusive_maximum
        output[:multipleOf] = schema.multiple_of if schema.multiple_of
      end

      def add_schema_string_constraints(output, schema)
        output[:minLength] = schema.min_length if schema.min_length
        output[:maxLength] = schema.max_length if schema.max_length
        output[:pattern] = schema.pattern if schema.pattern
      end

      def add_schema_array_fields(output, schema)
        output[:items] = export_schema(schema.items) if schema.items
        output[:minItems] = schema.min_items if schema.min_items
        output[:maxItems] = schema.max_items if schema.max_items
      end

      def add_schema_object_fields(output, schema)
        output[:properties] = schema.properties.transform_values { |s| export_schema(s) } if schema.properties.any?
        output[:required] = schema.required if schema.required.any?
        return if schema.additional_properties.nil?

        output[:additionalProperties] = export_additional_properties(schema.additional_properties)
      end

      def export_additional_properties(additional_props)
        return additional_props if [true, false].include?(additional_props)

        if additional_props.is_a?(Hash)
          if additional_props['$ref'] || additional_props[:$ref]
            ref = additional_props['$ref'] || additional_props[:$ref]
            ref = ref.gsub('#/definitions/', '#/components/schemas/')
            return { '$ref' => ref }
          end

          if additional_props[:canonical_name]
            return { '$ref' => "#/components/schemas/#{additional_props[:canonical_name]}" }
          end

          return additional_props
        end

        additional_props
      end

      def add_schema_composition(output, schema)
        output[:allOf] = schema.all_of.map { |s| export_schema(s) } if schema.all_of&.any?
        output[:oneOf] = schema.one_of.map { |s| export_schema(s) } if schema.one_of&.any?
        output[:anyOf] = schema.any_of.map { |s| export_schema(s) } if schema.any_of&.any?
        output[:not] = export_schema(schema.not) if schema.not
        output[:discriminator] = schema.discriminator if schema.discriminator
      end

      def add_schema_extensions(output, schema)
        schema.extensions&.each { |k, v| output[k] = v }
      end
    end
  end
end
