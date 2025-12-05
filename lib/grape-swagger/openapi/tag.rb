# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # Tag definition for grouping operations.
    class Tag
      attr_accessor :name, :description, :external_docs, :extensions

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @extensions ||= {}
      end

      def to_h
        hash = { name: name }
        hash[:description] = description if description
        hash[:externalDocs] = external_docs.to_h if external_docs
        extensions.each { |k, v| hash[k] = v } if extensions.any?
        hash
      end
    end

    # External documentation reference.
    class ExternalDoc
      attr_accessor :url, :description

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
      end

      def to_h
        hash = { url: url }
        hash[:description] = description if description
        hash
      end
    end
  end
end
