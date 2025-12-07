# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds OpenAPI SecuritySchemes from security_definitions configuration
      module SecurityBuilder
        private

        def build_security_definitions
          return unless options[:security_definitions]

          options[:security_definitions].each do |name, definition|
            scheme = build_security_scheme(definition)
            @spec.components.add_security_scheme(name, scheme)
          end

          @spec.security = options[:security] if options[:security]
        end

        def build_security_scheme(definition)
          scheme = OpenAPI::SecurityScheme.new
          scheme.type = convert_security_type(definition[:type])
          scheme.description = definition[:description]
          scheme.name = definition[:name]
          scheme.location = definition[:in]

          case definition[:type]
          when 'basic'
            scheme.type = 'http'
            scheme.scheme = 'basic'
          when 'oauth2'
            scheme.flows = build_oauth_flows(definition)
          end

          scheme
        end

        def convert_security_type(type)
          case type
          when 'basic' then 'http'
          else type
          end
        end

        def build_oauth_flows(definition)
          flow_type = case definition[:flow]
                      when 'implicit' then 'implicit'
                      when 'password' then 'password'
                      when 'application' then 'clientCredentials'
                      when 'accessCode' then 'authorizationCode'
                      else definition[:flow]
                      end

          {
            flow_type => {
              authorizationUrl: definition[:authorizationUrl],
              tokenUrl: definition[:tokenUrl],
              scopes: definition[:scopes]
            }.compact
          }
        end
      end
    end
  end
end
