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

        path_params = build_path_params(stackable_values)
        variant_types = collect_variant_types(stackable_values)

        fulfill_params(path_params, variant_types)
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

      # On Grape >= 3.3 `type: [A, B]` is documented in route.params via the
      # VariantCollectionCoercer's `#to_s`, which loses the original type list.
      # On earlier versions the same param appears as the stringified Array
      # `"[A, B]"` and the existing regex in DataType.parse_multi_type already
      # handles it; the recovery here is a no-op for those versions.
      #
      # The live coercer is still reachable through the CoerceValidator's
      # @converter, so we rebuild a name => types map keyed by the fully-qualified
      # param name (e.g. "group[inner]") to match route.params keys and avoid
      # clobbering same-named params at outer scopes.
      #
      # NOTE: @converter, @types, and @scope are private Grape ivars. If Grape
      # renames them, this method silently returns {} and swagger falls back to
      # the pre-fix broken output (coercer inspect string) — not a crash.
      def collect_variant_types(stackable_values)
        variant_types = {}
        return variant_types unless defined?(Grape::Validations::Types::VariantCollectionCoercer) &&
                                    defined?(Grape::Validations::Validators::CoerceValidator) &&
                                    stackable_values.respond_to?(:[])

        # StackableValues#[] concatenates inheritance levels and always returns
        # a flat Array of validator instances — no wrapping or flattening needed.
        stackable_values[:validations].each do |validator|
          next unless validator.is_a?(Grape::Validations::Validators::CoerceValidator)

          converter = validator.instance_variable_get(:@converter)
          next unless converter.is_a?(Grape::Validations::Types::VariantCollectionCoercer)

          # `.to_a` preserves the user-declared order for both Array and Set
          # storage shapes; `DataType.parse_multi_type` uses `.first` downstream.
          types = converter.instance_variable_get(:@types).to_a
          next if types.empty?

          scope = validator.instance_variable_get(:@scope)
          next unless scope.respond_to?(:full_name)

          validator.attrs.each do |attr|
            variant_types[scope.full_name(attr)] = types
          end
        end

        variant_types
      end

      def fulfill_params(path_params, variant_types)
        # Merge path params options into route params
        route.params.each_with_object({}) do |(param, definition), accum|
          # The route.params hash includes both parametrized params (with a string as a key)
          # and well-defined params from body/query (with a symbol as a key).
          # We avoid overriding well-defined params with parametrized ones.
          key = param.is_a?(String) ? param.to_sym : param
          next if param.is_a?(String) && accum.key?(key)

          defined_options = definition.is_a?(Hash) ? definition : {}
          defined_options = restore_variant_type(defined_options, param, variant_types)
          value = (path_params[param] || {}).merge(defined_options)
          accum[key] = value.empty? ? DEFAULT_PARAM_TYPE : value
        end
      end

      def restore_variant_type(defined_options, param, variant_types)
        types = variant_types[param.to_s]
        return defined_options unless types

        defined_options.merge(type: types)
      end
    end
  end
end
