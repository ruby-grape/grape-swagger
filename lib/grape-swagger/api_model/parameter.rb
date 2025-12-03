# frozen_string_literal: true

module GrapeSwagger
  module ApiModel
    # Parameter definition for query, path, header, or cookie parameters.
    # Note: body parameters in OAS2 become RequestBody in OAS3.
    class Parameter
      LOCATIONS = %w[query path header cookie].freeze

      attr_accessor :name, :location, :description,
                    :deprecated, :allow_empty_value,
                    :schema, :style, :explode, :allow_reserved,
                    :example, :examples,
                    :extensions,
                    # Swagger 2.0 specific (for backward compat)
                    :type, :format, :items, :collection_format,
                    :default, :enum, :minimum, :maximum,
                    :min_length, :max_length, :pattern

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @extensions ||= {}
      end

      def path?
        location == 'path'
      end

      def query?
        location == 'query'
      end

      def header?
        location == 'header'
      end

      def cookie?
        location == 'cookie'
      end

      # Set required value
      attr_writer :required

      # Ensure path parameters are always required
      def required
        path? || @required
      end

      # Convert Swagger 2.0 collectionFormat to OAS3 style/explode
      COLLECTION_FORMAT_STYLES = {
        'csv' => 'form',
        'ssv' => 'spaceDelimited',
        'tsv' => 'pipeDelimited',
        'pipes' => 'pipeDelimited',
        'multi' => 'form'
      }.freeze

      def style_from_collection_format
        COLLECTION_FORMAT_STYLES[collection_format]
      end

      def explode_from_collection_format
        collection_format == 'multi'
      end

      # Build schema from Swagger 2.0 inline properties
      def build_schema_from_inline
        return schema if schema

        Schema.new(
          type: type,
          format: format,
          items: items,
          default: default,
          enum: enum,
          minimum: minimum,
          maximum: maximum,
          min_length: min_length,
          max_length: max_length,
          pattern: pattern
        )
      end

      def to_h
        hash = {
          name: name,
          in: location,
          required: required
        }
        hash[:description] = description if description
        hash[:deprecated] = deprecated if deprecated
        hash[:allowEmptyValue] = allow_empty_value if allow_empty_value
        hash[:example] = example unless example.nil?
        hash[:examples] = examples if examples&.any?

        # Schema (OAS3 style)
        if schema
          hash[:schema] = schema.respond_to?(:to_h) ? schema.to_h : schema
        end

        # Style and explode (OAS3)
        hash[:style] = style if style
        hash[:explode] = explode unless explode.nil?
        hash[:allowReserved] = allow_reserved if allow_reserved

        extensions.each { |k, v| hash[k] = v } if extensions.any?

        hash
      end

      # Swagger 2.0 style output
      def to_swagger2_h
        hash = {
          name: name,
          in: location,
          required: required
        }
        hash[:description] = description if description

        # Inline type properties
        hash[:type] = type if type
        hash[:format] = format if format
        hash[:items] = items.respond_to?(:to_h) ? items.to_h : items if items
        hash[:collectionFormat] = collection_format if collection_format
        hash[:default] = default unless default.nil?
        hash[:enum] = enum if enum&.any?
        hash[:minimum] = minimum if minimum
        hash[:maximum] = maximum if maximum
        hash[:minLength] = min_length if min_length
        hash[:maxLength] = max_length if max_length
        hash[:pattern] = pattern if pattern

        extensions.each { |k, v| hash[k] = v } if extensions.any?

        hash
      end
    end
  end
end
