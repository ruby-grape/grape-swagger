# frozen_string_literal: true

module GrapeSwagger
  module Endpoint
    class HeaderParamsParser
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
          params = {
            documentation: {
              desc: definition["description"] || definition[:description],
              in: 'header'
            },
          }
          params[:type] = definition[:type].titleize if definition[:type]

          accum[name] = definition
            .symbolize_keys
            .except(:description, "description")
            .merge(params)
        end
      end
    end
  end
end
