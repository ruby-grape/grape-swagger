# frozen_string_literal: true

module GrapeSwagger
  module ApiModel
    # Security scheme definition.
    class SecurityScheme
      TYPES = %w[apiKey http oauth2 openIdConnect].freeze
      # Swagger 2.0 types
      SWAGGER2_TYPES = %w[basic apiKey oauth2].freeze

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

      def to_h
        hash = { type: type }
        hash[:description] = description if description

        case type
        when 'apiKey'
          hash[:name] = name
          hash[:in] = location
        when 'http'
          hash[:scheme] = scheme
          hash[:bearerFormat] = bearer_format if bearer_format
        when 'oauth2'
          hash[:flows] = flows if flows
        when 'openIdConnect'
          hash[:openIdConnectUrl] = open_id_connect_url
        end

        extensions.each { |k, v| hash[k] = v } if extensions.any?
        hash
      end

      # Swagger 2.0 style output
      def to_swagger2_h
        hash = { type: swagger2_type }
        hash[:description] = description if description

        case swagger2_type
        when 'apiKey'
          hash[:name] = name
          hash[:in] = location
        when 'basic'
          # No additional fields
        when 'oauth2'
          # Convert OAS3 flows to Swagger 2.0 flow
          if flows
            flow_type = flows.keys.first
            flow = flows[flow_type]
            hash[:flow] = swagger2_flow_type(flow_type)
            hash[:authorizationUrl] = flow[:authorizationUrl] if flow[:authorizationUrl]
            hash[:tokenUrl] = flow[:tokenUrl] if flow[:tokenUrl]
            hash[:scopes] = flow[:scopes] if flow[:scopes]
          end
        end

        extensions.each { |k, v| hash[k] = v } if extensions.any?
        hash
      end

      private

      def swagger2_type
        case type
        when 'http'
          scheme == 'basic' ? 'basic' : 'apiKey' # bearer becomes apiKey in 2.0
        else
          type
        end
      end

      def swagger2_flow_type(oas3_flow)
        case oas3_flow.to_s
        when 'implicit' then 'implicit'
        when 'password' then 'password'
        when 'clientCredentials' then 'application'
        when 'authorizationCode' then 'accessCode'
        else oas3_flow.to_s
        end
      end
    end

    # OAuth2 flow definition.
    class OAuthFlow
      attr_accessor :authorization_url, :token_url, :refresh_url, :scopes

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @scopes ||= {}
      end

      def to_h
        hash = {}
        hash[:authorizationUrl] = authorization_url if authorization_url
        hash[:tokenUrl] = token_url if token_url
        hash[:refreshUrl] = refresh_url if refresh_url
        hash[:scopes] = scopes if scopes.any?
        hash
      end
    end
  end
end
