# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds OpenAPI Servers array from host/basePath/schemes configuration
      module ServerBuilder
        private

        def build_servers
          host = GrapeSwagger::DocMethods::OptionalObject.build(:host, options, @request)
          base_path = GrapeSwagger::DocMethods::OptionalObject.build(:base_path, options, @request)
          schemes = normalize_schemes(options[:schemes])

          # Store for Swagger 2.0 compatibility
          @spec.host = host
          @spec.base_path = base_path
          @spec.schemes = schemes

          # Build OAS3 servers
          return unless host

          (schemes.presence || ['https']).each do |scheme|
            @spec.add_server(
              OpenAPI::Server.from_swagger2(host: host, base_path: base_path, scheme: scheme)
            )
          end
        end

        def normalize_schemes(schemes)
          return [] unless schemes

          schemes.is_a?(String) ? [schemes] : Array(schemes)
        end
      end
    end
  end
end
