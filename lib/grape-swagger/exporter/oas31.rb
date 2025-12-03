# frozen_string_literal: true

module GrapeSwagger
  module Exporter
    # Exports ApiModel::Spec to OpenAPI 3.1 format.
    # Extends OAS30 with 3.1-specific differences.
    class OAS31 < OAS30
      protected

      def openapi_version
        '3.1.0'
      end

      # OAS 3.1 uses type array for nullable instead of nullable keyword
      def nullable_keyword?
        false
      end

      def export_license
        license = spec.info.license.dup

        # OAS 3.1 supports identifier OR url (not both)
        # If identifier is present, prefer it over url
        if license[:identifier]
          license.delete(:url)
        end

        license
      end
    end
  end
end
