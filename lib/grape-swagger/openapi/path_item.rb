# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # Path item containing operations for a specific path.
    class PathItem
      HTTP_METHODS = %w[get put post delete options head patch trace].freeze

      attr_accessor :path, :summary, :description, :servers,
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

      def to_h
        hash = {}
        hash[:summary] = summary if summary
        hash[:description] = description if description
        hash[:servers] = servers.map(&:to_h) if servers&.any?
        hash[:parameters] = parameters.map(&:to_h) if parameters.any?

        HTTP_METHODS.each do |method|
          operation = public_send(method)
          hash[method.to_sym] = operation.to_h if operation
        end

        extensions.each { |k, v| hash[k] = v } if extensions.any?
        hash
      end

      # Swagger 2.0 style output
      def to_swagger2_h
        hash = {}
        hash[:parameters] = parameters.map(&:to_swagger2_h) if parameters.any?

        HTTP_METHODS.each do |method|
          operation = public_send(method)
          hash[method.to_sym] = operation.to_swagger2_h if operation
        end

        extensions.each { |k, v| hash[k] = v } if extensions.any?
        hash
      end
    end
  end
end
