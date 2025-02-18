# frozen_string_literal: true

module GrapeSwagger
  module RequestParamParsers
    class Route
      DEFAULT_PARAM_TYPE = { required: true, type: 'Integer' }.freeze

      attr_reader :route

      def self.parse(route, params, settings, endpoint)
        new(route, params, settings, endpoint).parse
      end

      def initialize(route, _params, _settings, _endpoint)
        @route = route
      end

      def parse
        stackable_values = route.app&.inheritable_setting&.namespace_stackable

        get_path_params(stackable_values)
        path_params = build_path_params(stackable_values)

        fulfill_params(path_params)
      end

      private

      def build_path_params(stackable_values)
        params = {}

        while stackable_values.is_a?(Grape::Util::StackableValues)
          params.merge!(fetch_inherited_params(stackable_values))
          stackable_values = stackable_values.inherited_values
        end

        params
      end

      def fetch_inherited_params(stackable_values)
        return {} unless stackable_values.new_values

        namespaces = stackable_values.new_values[:namespace] || []

        namespaces.each_with_object({}) do |namespace, params|
          space = namespace.space.to_s.gsub(':', '')
          params[space] = namespace.options || {}
        end
      end

      def fulfill_params(path_params)
        # Merge path params options into route params
        route.params.each_with_object({}) do |(param, definition), accum|
          # The route.params hash includes both parametrized params (with a string as a key)
          # and well-defined params from body/query (with a symbol as a key).
          # We avoid overriding well-defined params with parametrized ones.
          next if param.is_a?(String) && accum.key?(param.to_sym)

          value = (path_params[param] || {}).merge(
            definition.is_a?(Hash) ? definition : {}
          )

          accum[param.to_sym] = value.empty? ? DEFAULT_PARAM_TYPE : value
        end
      end

      # Iterates over namespaces recursively
      # to build a hash of path params with options, including type
      def get_path_params(stackable_values)
        params = {}
        return param unless stackable_values
        return params unless stackable_values.is_a? Grape::Util::StackableValues

        stackable_values&.new_values&.dig(:namespace)&.each do |namespace| # rubocop:disable Style/SafeNavigationChainLength
          space = namespace.space.to_s.gsub(':', '')
          params[space] = namespace.options || {}
        end
        inherited_params = get_path_params(stackable_values.inherited_values)
        inherited_params.merge(params)
      end
    end
  end
end
