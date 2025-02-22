# frozen_string_literal: true

module GrapeSwagger
  module RequestParamParsers
    class Headers
      attr_reader :route

      def self.parse(route, params, settings, endpoint)
        new(route, params, settings, endpoint).parse
      end

      def initialize(route, _params, _settings, _endpoint)
        @route = route
      end

      def parse
        return {} unless route.headers

        route.headers.each_with_object({}) do |(name, definition), accum|
          # Extract the description from any key type (string or symbol)
          description = definition[:description] || definition['description']
          doc = { desc: description, in: 'header' }

          header_attrs = definition.symbolize_keys.except(:description, 'description')
          header_attrs[:type] = definition[:type].titleize if definition[:type]
          header_attrs[:documentation] = doc

          accum[name] = header_attrs
        end
      end
    end
  end
end
