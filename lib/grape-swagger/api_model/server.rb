# frozen_string_literal: true

module GrapeSwagger
  module ApiModel
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

      def to_h
        hash = { url: url }
        hash[:description] = description if description
        hash[:variables] = variables.transform_values(&:to_h) if variables.any?
        hash
      end
    end

    # Server variable for templated URLs.
    class ServerVariable
      attr_accessor :default, :description, :enum

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
      end

      def to_h
        hash = { default: default }
        hash[:description] = description if description
        hash[:enum] = enum if enum&.any?
        hash
      end
    end
  end
end
