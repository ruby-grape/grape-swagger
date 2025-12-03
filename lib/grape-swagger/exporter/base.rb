# frozen_string_literal: true

module GrapeSwagger
  module Exporter
    # Base exporter class for converting ApiModel::Spec to output format.
    class Base
      attr_reader :spec

      def initialize(spec)
        @spec = spec
      end

      def export
        raise NotImplementedError, "Subclasses must implement #export"
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

      # Remove nil/empty values from hash
      def compact_hash(hash)
        case hash
        when Hash
          hash.each_with_object({}) do |(k, v), result|
            compacted = compact_hash(v)
            result[k] = compacted unless blank?(compacted)
          end
        when Array
          hash.map { |v| compact_hash(v) }.reject { |v| blank?(v) }
        else
          hash
        end
      end

      def blank?(value)
        return true if value.nil?
        return value.empty? if value.respond_to?(:empty?)

        false
      end
    end
  end
end
