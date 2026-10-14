# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # Parameter definition for query, path, header, or cookie parameters.
    # Note: body parameters in OAS2 become RequestBody in OAS3.
    class Parameter
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

      # OAS 3 style for a Swagger 2.0 collectionFormat, or nil when OAS 3 has no equivalent
      # (tsv, brackets) or no collectionFormat is set.
      def style_from_collection_format
        collection_style&.first
      end

      def explode_from_collection_format
        collection_style&.last
      end

      # Set required value
      attr_writer :required

      # Ensure path parameters are always required
      def required
        path? || @required
      end

      private

      def collection_style
        case [collection_format.to_s, location]
        in ['multi', 'query'] then ['form', true]
        in ['csv', 'query'] then ['form', false]
        in ['ssv', 'query'] then ['spaceDelimited', false]
        in ['pipes', 'query'] then ['pipeDelimited', false]
        in ['csv', 'path' | 'header'] then ['simple', false]
        else nil
        end
      end
    end
  end
end
