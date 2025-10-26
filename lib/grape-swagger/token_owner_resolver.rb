# frozen_string_literal: true

module GrapeSwagger
  class TokenOwnerResolver
    class << self
      SUPPORTED_ARITY_TYPES = %i[req opt rest keyreq key keyrest].freeze
      UNRESOLVED = Object.new.freeze
      private_constant :UNRESOLVED

      def resolve(endpoint, method_name)
        return if method_name.nil?

        method_name = method_name.to_sym
        return endpoint.public_send(method_name) if endpoint.respond_to?(method_name, true)

        helper_value = resolve_from_helpers(endpoint, method_name)
        return helper_value unless helper_value.equal?(UNRESOLVED)

        raise NoMethodError, "undefined method `#{method_name}` for #{endpoint.inspect}"
      end

      def evaluate_proc(callable, token_owner)
        return callable.call unless accepts_argument?(callable)

        callable.call(token_owner)
      end

      private

      def accepts_argument?(callable)
        return false unless callable.respond_to?(:parameters)

        callable.parameters.any? { |type, _| SUPPORTED_ARITY_TYPES.include?(type) }
      end

      def resolve_from_helpers(endpoint, method_name)
        helpers = gather_helpers(endpoint)
        return UNRESOLVED if helpers.empty?

        helpers.each do |helper|
          resolved = resolve_from_helper(endpoint, helper, method_name)
          return resolved unless resolved.equal?(UNRESOLVED)
        end

        UNRESOLVED
      end

      def gather_helpers(endpoint)
        return [] if endpoint.nil?

        helpers = []
        endpoint_helpers = fetch_endpoint_helpers(endpoint)
        helpers.concat(normalize_helpers(endpoint_helpers)) if endpoint_helpers

        stackable_helpers = fetch_stackable_helpers(endpoint)
        helpers.concat(normalize_helpers(stackable_helpers)) if stackable_helpers

        helpers.compact.uniq
      end

      def resolve_from_helper(endpoint, helper, method_name)
        if helper.is_a?(Module)
          return UNRESOLVED unless helper_method_defined?(helper, method_name)

          return helper.instance_method(method_name).bind(endpoint).call
        end

        helper.respond_to?(method_name, true) ? helper.public_send(method_name) : UNRESOLVED
      rescue NameError
        UNRESOLVED
      end

      def helper_method_defined?(helper, method_name)
        helper.method_defined?(method_name) || helper.private_method_defined?(method_name)
      end

      def normalize_helpers(helpers)
        case helpers
        when nil, false
          []
        when Module
          [helpers]
        when Array
          helpers.compact
        else
          if helpers.respond_to?(:key?) && helpers.respond_to?(:[]) && helpers.key?(:helpers)
            normalize_helpers(helpers[:helpers])
          elsif helpers.respond_to?(:to_a)
            Array(helpers.to_a).flatten.compact
          else
            Array(helpers).compact
          end
        end
      end

      def fetch_endpoint_helpers(endpoint)
        return unless endpoint.respond_to?(:helpers, true)

        endpoint.__send__(:helpers)
      rescue StandardError
        nil
      end

      def fetch_stackable_helpers(endpoint)
        return unless endpoint.respond_to?(:inheritable_setting, true)

        setting = endpoint.__send__(:inheritable_setting)
        return unless setting.respond_to?(:namespace_stackable)

        namespace_stackable = setting.namespace_stackable
        return unless namespace_stackable.respond_to?(:[])

        namespace_stackable[:helpers]
      rescue StandardError
        nil
      end
    end
  end
end
