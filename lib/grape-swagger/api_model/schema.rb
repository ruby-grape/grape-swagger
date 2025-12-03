# frozen_string_literal: true

module GrapeSwagger
  module ApiModel
    # Version-agnostic JSON Schema representation.
    # Used for request/response bodies, parameters, and component schemas.
    class Schema
      attr_accessor :type, :format, :properties, :items, :additional_properties,
                    :required, :enum, :nullable, :default,
                    :minimum, :maximum, :exclusive_minimum, :exclusive_maximum,
                    :min_length, :max_length, :min_items, :max_items,
                    :pattern, :multiple_of,
                    :all_of, :one_of, :any_of, :not,
                    :discriminator,
                    :canonical_name, :description, :example, :examples,
                    :read_only, :write_only, :deprecated,
                    :extensions,
                    # OpenAPI 3.1 specific
                    :json_schema, :content_media_type, :content_encoding

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @properties ||= {}
        @required ||= []
        @extensions ||= {}
      end

      def ref?
        !canonical_name.nil? && !canonical_name.empty?
      end

      def primitive?
        %w[string integer number boolean].include?(type) && !ref?
      end

      def array?
        type == 'array'
      end

      def object?
        type == 'object' || properties.any?
      end

      def composed?
        all_of || one_of || any_of
      end

      def add_property(name, schema)
        @properties[name.to_s] = schema
      end

      def mark_required(name)
        @required << name.to_s unless @required.include?(name.to_s)
      end

      def to_h
        hash = {}
        hash[:type] = type if type
        hash[:format] = format if format
        hash[:description] = description if description
        hash[:enum] = enum if enum&.any?
        hash[:default] = default unless default.nil?
        hash[:nullable] = nullable if nullable
        hash[:example] = example unless example.nil?
        hash[:examples] = examples if examples&.any?
        hash[:readOnly] = read_only if read_only
        hash[:writeOnly] = write_only if write_only
        hash[:deprecated] = deprecated if deprecated

        # Numeric constraints
        hash[:minimum] = minimum if minimum
        hash[:maximum] = maximum if maximum
        hash[:exclusiveMinimum] = exclusive_minimum if exclusive_minimum
        hash[:exclusiveMaximum] = exclusive_maximum if exclusive_maximum
        hash[:multipleOf] = multiple_of if multiple_of

        # String constraints
        hash[:minLength] = min_length if min_length
        hash[:maxLength] = max_length if max_length
        hash[:pattern] = pattern if pattern

        # Array constraints
        hash[:minItems] = min_items if min_items
        hash[:maxItems] = max_items if max_items
        hash[:items] = items.to_h if items

        # Object properties
        hash[:properties] = properties.transform_values(&:to_h) if properties.any?
        hash[:required] = required if required.any?
        hash[:additionalProperties] = additional_properties unless additional_properties.nil?

        # Composition
        hash[:allOf] = all_of.map(&:to_h) if all_of&.any?
        hash[:oneOf] = one_of.map(&:to_h) if one_of&.any?
        hash[:anyOf] = any_of.map(&:to_h) if any_of&.any?
        hash[:not] = self.not.to_h if self.not
        hash[:discriminator] = discriminator if discriminator

        # Extensions
        extensions.each { |k, v| hash[k] = v } if extensions.any?

        hash
      end
    end
  end
end
