# frozen_string_literal: true

require_relative 'exporter/base'
require_relative 'exporter/swagger2'
require_relative 'exporter/oas30'
require_relative 'exporter/oas31'

module GrapeSwagger
  module Exporter
    # Exporters convert ApiModel::Spec to specific output formats.
    # Each exporter produces a version-specific OpenAPI/Swagger document.

    class << self
      # Factory method to get the appropriate exporter for a version
      def for_version(version)
        case normalize_version(version)
        when :swagger_20, nil
          Swagger2
        when :oas_30
          OAS30
        when :oas_31
          OAS31
        else
          Swagger2
        end
      end

      # Export a spec using the specified version
      def export(spec, version: nil)
        exporter_class = for_version(version)
        exporter_class.new(spec).export
      end

      private

      def normalize_version(version)
        return nil if version.nil?

        case version.to_s.downcase
        when '2.0', '2', 'swagger', 'swagger2', 'swagger_20'
          :swagger_20
        when '3.0', '3.0.0', '3.0.3', 'oas30', 'openapi30', 'openapi_30'
          :oas_30
        when '3.1', '3.1.0', 'oas31', 'openapi31', 'openapi_31'
          :oas_31
        else
          nil
        end
      end
    end
  end
end
