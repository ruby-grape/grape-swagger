# frozen_string_literal: true

module GrapeSwagger
  module Endpoint
    class Visibility
      class << self
        def hidden_route?(route, options)
          return !public_route?(route, options) if options[:default_route_visibility] == :hidden

          scan_route_for_value(:hidden, route, options)
        end

        def public_route?(route, options)
          scan_route_for_value(:public, route, options)
        end

        def hidden_parameter?(value)
          return false if value[:required]

          if value.dig(:documentation, :hidden).is_a?(Proc)
            value.dig(:documentation, :hidden).call
          else
            value.dig(:documentation, :hidden)
          end
        end

        private

        def scan_route_for_value(key, route, options)
          key = key.to_sym
          route_value = route.settings.try(:[], :swagger).try(:[], key)
          route_value = route.options[key] if route.options.key?(key)
          return route_value unless route_value.is_a?(Proc)

          options[:token_owner] ? route_value.call(send(options[:token_owner].to_sym)) : route_value.call
        end
      end
    end
  end
end
