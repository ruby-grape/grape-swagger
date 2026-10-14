# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # Path item containing operations for a specific path.
    class PathItem
      HTTP_METHODS = %w[get put post delete options head patch trace].freeze

      attr_accessor :path, :summary, :description,
                    :parameters, :extensions,
                    :get, :put, :post, :delete, :options, :head, :patch, :trace

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @parameters ||= []
        @extensions ||= {}
      end

      def operations
        HTTP_METHODS.filter_map { |method| [method, public_send(method)] if public_send(method) }
      end

      def add_operation(method, operation)
        public_send("#{method.downcase}=", operation)
      end
    end
  end
end
