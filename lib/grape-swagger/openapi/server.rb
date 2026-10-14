# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # Server definition for OpenAPI 3.x.
    # For Swagger 2.0, this is converted to host/basePath/schemes.
    class Server
      attr_accessor :url, :description, :variables

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @variables ||= {}
      end

      # Build from Swagger 2.0 components
      def self.from_swagger2(host:, base_path: nil, scheme: 'https')
        url = "#{scheme}://#{host}"
        url += base_path if base_path && base_path != '/'
        new(url: url)
      end
    end
  end
end
