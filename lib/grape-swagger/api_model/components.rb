# frozen_string_literal: true

module GrapeSwagger
  module ApiModel
    # Components container (OAS3) / Definitions container (Swagger 2.0).
    class Components
      attr_accessor :schemas, :responses, :parameters, :examples,
                    :request_bodies, :headers, :security_schemes,
                    :links, :callbacks, :extensions

      def initialize
        @schemas = {}
        @responses = {}
        @parameters = {}
        @examples = {}
        @request_bodies = {}
        @headers = {}
        @security_schemes = {}
        @links = {}
        @callbacks = {}
        @extensions = {}
      end

      def add_schema(name, schema)
        @schemas[name] = schema
      end

      def add_security_scheme(name, scheme)
        @security_schemes[name] = scheme
      end

      def empty?
        schemas.empty? && responses.empty? && parameters.empty? &&
          examples.empty? && request_bodies.empty? && headers.empty? &&
          security_schemes.empty? && links.empty? && callbacks.empty?
      end

      def to_h
        hash = {}
        add_schema_components(hash)
        add_other_components(hash)
        extensions.each { |k, v| hash[k] = v } if extensions.any?
        hash
      end

      # Swagger 2.0 style - definitions and securityDefinitions are separate
      def definitions_h
        schemas.transform_values { |s| s.respond_to?(:to_h) ? s.to_h : s }
      end

      def security_definitions_h
        security_schemes.transform_values(&:to_swagger2_h)
      end

      private

      def add_schema_components(hash)
        hash[:schemas] = schemas.transform_values { |s| s.respond_to?(:to_h) ? s.to_h : s } if schemas.any?
        hash[:responses] = responses.transform_values(&:to_h) if responses.any?
        hash[:parameters] = parameters.transform_values(&:to_h) if parameters.any?
        hash[:examples] = examples if examples.any?
        hash[:requestBodies] = request_bodies.transform_values(&:to_h) if request_bodies.any?
      end

      def add_other_components(hash)
        hash[:headers] = headers.transform_values(&:to_h) if headers.any?
        hash[:securitySchemes] = security_schemes.transform_values(&:to_h) if security_schemes.any?
        hash[:links] = links if links.any?
        hash[:callbacks] = callbacks if callbacks.any?
      end
    end
  end
end
