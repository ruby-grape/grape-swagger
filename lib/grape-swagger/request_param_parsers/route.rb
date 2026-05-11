# frozen_string_literal: true

module GrapeSwagger
  module RequestParamParsers
    class Route
      DEFAULT_PARAM_TYPE = { required: true, type: 'Integer' }.freeze
      IGNORED_FALLBACK_PATH_PARAMS = %w[format version].freeze

      attr_reader :route

      def self.parse(route, params, settings, endpoint)
        new(route, params, settings, endpoint).parse
      end

      def initialize(route, _params, _settings, _endpoint)
        @route = route
      end

      def parse
        stackable_values = route.app&.inheritable_setting&.namespace_stackable

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
        route_params.each_with_object({}) do |(param, definition), accum|
          # The route.params hash includes both parametrized params (with a string as a key)
          # and well-defined params from body/query (with a symbol as a key).
          # We avoid overriding well-defined params with parametrized ones.
          key = param.is_a?(String) ? param.to_sym : param
          next if param.is_a?(String) && accum.key?(key)

          defined_options = definition.is_a?(Hash) ? definition : {}
          path_options = path_params[param] || path_params[param.to_s] || path_params[param.to_sym] || {}
          value = path_options.merge(defined_options)
          accum[key] = value.empty? ? DEFAULT_PARAM_TYPE : value
        end
      end

      def route_params
        route.params
      rescue NoMethodError => e
        raise unless e.message.include?('named_captures')

        fallback_route_params
      end

      def fallback_route_params
        path_params = extract_path_param_names.to_h { |param| [param, {}] }
        defined_params = route.respond_to?(:options) ? route.options[:params] : nil
        return path_params unless defined_params.is_a?(Hash)

        path_params.merge(defined_params)
      end

      def extract_path_param_names
        return extract_path_param_names_from_path unless route.respond_to?(:pattern_regexp)

        regexp = route.pattern_regexp
        return extract_path_param_names_from_path unless regexp.respond_to?(:named_captures)

        names = regexp.named_captures.keys
        names.empty? ? extract_path_param_names_from_path : names
      rescue StandardError
        extract_path_param_names_from_path
      end

      def extract_path_param_names_from_path
        return [] unless route.respond_to?(:path)

        route.path
             .scan(/:([a-zA-Z_][a-zA-Z0-9_]*)/)
             .flatten
             .reject { |name| IGNORED_FALLBACK_PATH_PARAMS.include?(name) }
      end
    end
  end
end
