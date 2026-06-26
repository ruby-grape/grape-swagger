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
          params = merge_path_params(fetch_inherited_params(stackable_values), params)
          stackable_values = stackable_values.inherited_values
        end

        params
      end

      def merge_path_params(outer_params, inner_params)
        outer_params.merge(inner_params) do |_key, outer_options, inner_options|
          merge_path_param_options(outer_options, inner_options)
        end
      end

      def merge_path_param_options(outer_options, inner_options)
        return inner_options unless outer_options.is_a?(Hash) && inner_options.is_a?(Hash)

        outer_options.merge(inner_options) do |_key, outer_value, inner_value|
          merge_path_param_options(outer_value, inner_value)
        end
      end

      def fetch_inherited_params(stackable_values)
        return {} unless stackable_values.new_values

        namespaces = stackable_values.new_values[:namespace] || []

        namespaces.each_with_object({}) do |namespace, params|
          space = namespace.space.to_s.delete_prefix(':')
          params[space.to_sym] = namespace.options || {}
        end
      end

      # Grape 3.2+ serializes `type: [A, B]` via VariantCollectionCoercer#to_s, losing the type list.
      # Grape 3.2+ stores validator metadata as Hash entries; older supported versions use
      # CoerceValidator object instances and require private-ivar reads below.
      # If the internal structure changes in a future Grape version this silently returns {}.
      def collect_variant_types(stackable_values)
        variant_types = {}
        return variant_types unless defined?(Grape::Validations::Types::VariantCollectionCoercer) &&
                                    defined?(Grape::Validations::Validators::CoerceValidator) &&
                                    stackable_values.respond_to?(:[])

        # StackableValues#[] concatenates this level and all inherited levels;
        # no explicit chain walk is needed here.
        (stackable_values[:validations] || []).each do |validator|
          attrs, scope, converter = extract_variant_validator_parts(validator)
          next unless attrs
          next unless converter.is_a?(Grape::Validations::Types::VariantCollectionCoercer)

          # TODO: use a public API once Grape exposes VariantCollectionCoercer#types.
          types = converter.instance_variable_get(:@types).to_a
          next if types.empty?

          next unless scope.respond_to?(:full_name)

          attrs.each do |attr|
            # Key format must match param.to_s in restore_variant_type.
            variant_types[scope.full_name(attr)] = types
          end
        end

        variant_types
      end

      def extract_variant_validator_parts(validator)
        if validator.is_a?(Hash)
          return unless validator[:validator_class] == Grape::Validations::Validators::CoerceValidator

          attrs = Array(validator[:attributes])
          scope = validator[:params_scope]
          converter = validator[:options].is_a?(Hash) ? validator[:options][:type] : nil
          return [attrs, scope, converter]
        end

        return unless validator.is_a?(Grape::Validations::Validators::CoerceValidator)
        return unless validator.respond_to?(:attrs)

        attrs = Array(validator.attrs)
        scope = validator.instance_variable_get(:@scope)
        converter = validator.instance_variable_get(:@converter)
        [attrs, scope, converter]
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
          path_options = path_params[key] || {}
          value = path_options.merge(defined_options)
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
