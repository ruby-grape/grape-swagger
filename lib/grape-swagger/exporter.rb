# frozen_string_literal: true

require_relative 'exporter/base'
require_relative 'exporter/oas30'
require_relative 'exporter/oas31'

module GrapeSwagger
  module Exporter
    # Exporters convert a GrapeSwagger::OpenAPI::Document to an OpenAPI 3.x document hash.
    # Swagger 2.0 is not produced here; it stays on the legacy generator.

    class << self
      VERSION_EXPORTERS = {
        oas_30: OAS30,
        oas_31: OAS31
      }.freeze

      # Exporter class for an OAS 3.x version, nil for Swagger 2.0 (produced by the legacy generator).
      def for_version(version)
        VERSION_EXPORTERS[normalize_version(version)]
      end

      # Raises ArgumentError for an unsupported version; call at configuration time to fail early.
      def validate_version!(version)
        normalize_version(version)
        version
      end

      def legacy?(version)
        for_version(version).nil?
      end

      # Export a spec using the specified version
      def export(spec, version: nil)
        exporter_class = for_version(version)
        raise ArgumentError, 'Swagger 2.0 is produced by the legacy generator, not an exporter' if exporter_class.nil?

        exporter_class.new(spec).export
      end

      private

      def normalize_version(version)
        return nil if version.nil?

        case version.to_s.downcase
        when '2.0', '2', 'swagger', 'swagger2', 'swagger_20'
          nil
        when /\A3\.0(\.\d+)?\z/, 'oas30', 'openapi30', 'openapi_30'
          :oas_30
        when /\A3\.1(\.\d+)?\z/, 'oas31', 'openapi31', 'openapi_31'
          :oas_31
        else
          raise ArgumentError,
                "Unsupported openapi_version #{version.inspect}. Supported versions: '2.0', '3.0', '3.1' " \
                "(including patch versions such as '3.0.1')"
        end
      end
    end
  end
end
