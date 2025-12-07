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

      def content
        media_types.each_with_object({}) do |mt, hash|
          hash[mt.mime_type] = mt.to_h
        end
      end

      def to_h
        hash = {}
        hash[:description] = description if description
        hash[:required] = required unless required.nil?
        hash[:content] = content if media_types.any?
        extensions.each { |k, v| hash[k] = v } if extensions.any?
        hash
      end

      # Convert to Swagger 2.0 body parameter
      def to_swagger2_parameter
        primary_media_type = media_types.first
        return nil unless primary_media_type

        schema = primary_media_type.schema
        schema_hash = schema.respond_to?(:to_h) ? schema.to_h : schema
        {
          name: 'body',
          in: 'body',
          required: required,
          description: description,
          schema: schema_hash
        }.compact
      end
    end
  end
end
