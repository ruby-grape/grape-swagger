# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # Media type object wrapping a schema with content-type.
    # Used in requestBody and responses for OAS3.
    class MediaType
      attr_accessor :mime_type, :schema, :example, :examples, :encoding, :extensions

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @mime_type ||= 'application/json'
        @extensions ||= {}
      end
    end
  end
end
