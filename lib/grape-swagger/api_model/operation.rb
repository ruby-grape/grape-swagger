# frozen_string_literal: true

module GrapeSwagger
  module ApiModel
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

      def to_h
        hash = {}
        add_operation_basics(hash)
        add_oas3_fields(hash)
        add_operation_common(hash)
        hash
      end

      # Swagger 2.0 style output
      def to_swagger2_h
        hash = {}
        add_operation_basics(hash)
        add_swagger2_content_types(hash)
        add_swagger2_params(hash)
        add_swagger2_responses(hash)
        add_operation_common(hash)
        hash
      end

      private

      def add_operation_basics(hash)
        hash[:operationId] = operation_id if operation_id
        hash[:summary] = summary if summary
        hash[:description] = description if description
        hash[:tags] = tags if tags.any?
      end

      def add_oas3_fields(hash)
        hash[:externalDocs] = external_docs if external_docs
        hash[:parameters] = parameters.map(&:to_h) if parameters.any?
        hash[:requestBody] = request_body.to_h if request_body
        hash[:responses] = responses.transform_values(&:to_h) if responses.any?
        hash[:callbacks] = callbacks if callbacks&.any?
        hash[:servers] = servers.map(&:to_h) if servers&.any?
      end

      def add_operation_common(hash)
        hash[:deprecated] = deprecated if deprecated
        hash[:security] = security if security&.any?
        extensions.each { |k, v| hash[k] = v } if extensions.any?
      end

      def add_swagger2_content_types(hash)
        hash[:produces] = produces if produces&.any?
        hash[:consumes] = consumes if consumes&.any?
      end

      def add_swagger2_params(hash)
        all_params = parameters.map(&:to_swagger2_h)
        all_params << request_body.to_swagger2_parameter if request_body
        hash[:parameters] = all_params.compact if all_params.any?
      end

      def add_swagger2_responses(hash)
        hash[:responses] = responses.transform_values(&:to_swagger2_h) if responses.any?
      end
    end
  end
end
