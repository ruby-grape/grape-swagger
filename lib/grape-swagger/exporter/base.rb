# frozen_string_literal: true

module GrapeSwagger
  module Exporter
    # Base exporter class for converting OpenAPI::Document to output format.
    class Base
      attr_reader :spec

      def initialize(spec)
        @spec = spec
      end

      def export
        raise NotImplementedError, 'Subclasses must implement #export'
      end

      protected

      # Deep convert symbols to strings in hash keys
      def stringify_keys(hash)
        case hash
        when Hash
          hash.each_with_object({}) do |(k, v), result|
            result[k.to_s] = stringify_keys(v)
          end
        when Array
          hash.map { |v| stringify_keys(v) }
        else
          hash
        end
      end

      # Deep convert strings to symbols in hash keys
      def symbolize_keys(hash)
        case hash
        when Hash
          hash.each_with_object({}) do |(k, v), result|
            result[k.to_sym] = symbolize_keys(v)
          end
        when Array
          hash.map { |v| symbolize_keys(v) }
        else
          hash
        end
      end

      # Remove nil values and empty containers from hash, but preserve intentionally empty arrays
      # like security: [] or scopes: []
      def compact_hash(hash, preserve_empty_arrays: false)
        case hash
        when Hash
          hash.each_with_object({}) do |(k, v), result|
            # Preserve empty arrays in certain contexts (e.g., security scopes)
            if v.is_a?(Array) && v.empty? && preserve_empty_arrays
              result[k] = v
            else
              compacted = compact_hash(v, preserve_empty_arrays: true)
              result[k] = compacted unless blank?(compacted)
            end
          end
        when Array
          # Don't reject empty hashes from arrays (e.g., security: [{api_key: []}])
          hash.map { |v| compact_hash(v, preserve_empty_arrays: preserve_empty_arrays) }.compact
        else
          hash
        end
      end

      def blank?(value)
        return true if value.nil?
        # Only consider empty if it's an empty hash (not array - arrays can be intentionally empty)
        return true if value.is_a?(Hash) && value.empty?

        false
      end
    end
  end
end
