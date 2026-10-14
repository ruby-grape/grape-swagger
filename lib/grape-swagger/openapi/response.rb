# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # Response definition.
    class Response
      attr_accessor :status_code, :description, :media_types, :headers,
                    :links, :extensions,
                    # Swagger 2.0 specific
                    :schema, :examples

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @media_types ||= []
        @headers ||= {}
        @extensions ||= {}
      end

      def add_media_type(mime_type, schema:, example: nil, examples: nil)
        @media_types << MediaType.new(
          mime_type: mime_type,
          schema: schema,
          example: example,
          examples: examples
        )
      end
    end

    # Header definition.
    class Header
      attr_accessor :name, :description, :required, :deprecated,
                    :schema, :style, :explode,
                    :example, :examples, :extensions,
                    # Swagger 2.0 specific
                    :type, :format, :items

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @extensions ||= {}
      end
    end
  end
end
