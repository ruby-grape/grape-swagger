# frozen_string_literal: true

module GrapeSwagger
  module ApiModel
    # Media type object wrapping a schema with content-type.
    # Used in requestBody and responses for OAS3.
    class MediaType
      attr_accessor :mime_type, :schema, :example, :examples, :encoding, :extensions

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @mime_type ||= 'application/json'
        @extensions ||= {}
      end

      def to_h
        hash = {}
        hash[:schema] = schema.respond_to?(:to_h) ? schema.to_h : schema if schema
        hash[:example] = example unless example.nil?
        hash[:examples] = examples if examples&.any?
        hash[:encoding] = encoding if encoding&.any?
        extensions.each { |k, v| hash[k] = v } if extensions.any?
        hash
      end
    end
  end
end
