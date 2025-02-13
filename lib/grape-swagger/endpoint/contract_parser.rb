# frozen_string_literal: true

module GrapeSwagger
  module Endpoint
    class ContractParser
      attr_reader :route, :params, :settings, :endpoint

      class << self
        def parse(route, params, settings, endpoint)
          new(route, params, settings, endpoint).parse
        end

        alias parse_request_params parse
      end

      def initialize(route, params, settings, endpoint)
        @route = route
        @params = params
        @settings = settings
        @endpoint = endpoint
      end

      def parse
        # return {} unless contract_defined?

        {}
      end

      private

      def contract_defined?
        endpoint_settings = @endpoint&.route&.app&.inheritable_setting&.namespace_stackable
        binding.pry
        false unless endpoint_settings
      end
    end
  end
end
