# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # Request body definition for OAS3.
    # In Swagger 2.0, this is converted to a body parameter.
    class RequestBody
      attr_accessor :description, :required, :media_types, :extensions

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @media_types ||= []
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
  end
end
