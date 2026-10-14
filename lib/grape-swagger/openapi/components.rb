# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
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
    end
  end
end
