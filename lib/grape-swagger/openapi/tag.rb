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
    end
  end
end
