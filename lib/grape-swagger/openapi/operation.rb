# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # HTTP operation (GET, POST, etc.) definition.
    class Operation
      attr_accessor :operation_id, :summary, :description,
                    :tags, :external_docs,
                    :parameters, :request_body,
                    :responses, :callbacks,
                    :security, :servers,
                    :deprecated,
                    :extensions,
                    # Swagger 2.0 specific
                    :produces, :consumes

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @tags ||= []
        @parameters ||= []
        @responses ||= {}
        @extensions ||= {}
      end

      def add_parameter(param)
        @parameters << param
      end

      def add_response(status_code, response)
        @responses[status_code.to_s] = response
      end
    end
  end
end
