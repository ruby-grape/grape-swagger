# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # Security scheme definition.
    class SecurityScheme
      attr_accessor :type, :name, :description,
                    :location, # 'in' field - query, header, cookie
                    :scheme, :bearer_format, # for http type
                    :flows, # for oauth2
                    :open_id_connect_url, # for openIdConnect
                    :extensions

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @extensions ||= {}
      end
    end
  end
end
