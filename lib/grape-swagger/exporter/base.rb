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

      # Hash keys whose empty hash is data: an OAuth2 flow's `scopes` is required even when empty,
      # and `default: {}` is a legitimate default value.
      KEEP_EMPTY_HASH_KEYS = %w[scopes default].freeze

      protected

      # Remove nil values and empty hashes, but preserve intentionally empty arrays like
      # security: [] and the empty hashes named in KEEP_EMPTY_HASH_KEYS.
      def compact_hash(hash, preserve_empty_arrays: false)
        case hash
        when Hash
          hash.each_with_object({}) do |(k, v), result|
            # Preserve empty arrays in certain contexts (e.g., security scopes)
            if v.is_a?(Array) && v.empty? && preserve_empty_arrays
              result[k] = v
            else
              compacted = compact_hash(v, preserve_empty_arrays: true)
              keep_empty = compacted == {} && KEEP_EMPTY_HASH_KEYS.include?(k.to_s)
              result[k] = compacted if keep_empty || !blank?(compacted)
            end
          end
        when Array
          # Keep array members as they are: empty hashes (security: [{api_key: []}]) and nils
          # (a nullable enum's null member) are data.
          hash.map { |v| compact_hash(v, preserve_empty_arrays: preserve_empty_arrays) }
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
