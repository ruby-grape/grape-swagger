# frozen_string_literal: true

module GrapeSwagger
  class TokenOwnerResolver
    class << self
      SUPPORTED_ARITY_TYPES = %i[req opt rest keyreq key keyrest].freeze

      def resolve(endpoint, method_name)
        return if method_name.nil?

        method_name = method_name.to_sym
        unless endpoint.respond_to?(method_name, true)
          raise NoMethodError, "undefined method `#{method_name}` for #{endpoint.inspect}"
        end

        endpoint.public_send(method_name)
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
    end
  end
end
