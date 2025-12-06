# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    # Builds output from routes in either Swagger 2.0 or OpenAPI 3.x format
    module OutputBuilder
      class << self
        def build(combi_routes, endpoint, target_class, options)
          if options[:openapi_version]
            build_openapi3(combi_routes, endpoint, target_class, options)
          else
            build_swagger2(combi_routes, endpoint, target_class, options)
          end
        end

        private

        def build_swagger2(combi_routes, endpoint, target_class, options)
          output = endpoint.swagger_object(
            target_class,
            endpoint.request,
            options
          )

          paths, definitions = endpoint.path_and_definition_objects(combi_routes, options)
          tags = tags_from(paths, options)

          output[:tags] = tags unless tags.empty? || paths.blank?
          output[:paths] = paths unless paths.blank?
          output[:definitions] = definitions unless definitions.blank?

          output
        end

        def build_openapi3(combi_routes, endpoint, target_class, options)
          version = options[:openapi_version]

          builder = GrapeSwagger::OpenAPI::Builder::FromRoutes.new(
            endpoint, target_class, endpoint.request, options
          )
          spec = builder.build(combi_routes)

          apply_oas31_options(spec, options) if version.to_s.start_with?('3.1')

          GrapeSwagger::Exporter.export(spec, version: version)
        end

        def apply_oas31_options(spec, options)
          spec.json_schema_dialect = options[:json_schema_dialect] if options[:json_schema_dialect]
          Webhooks.apply(spec, options[:webhooks]) if options[:webhooks]
        end

        def tags_from(paths, options)
          tags = GrapeSwagger::DocMethods::TagNameDescription.build(paths)

          if options[:tags]
            names = options[:tags].map { |t| t[:name] }
            tags.reject! { |t| names.include?(t[:name]) }
            tags += options[:tags]
          end

          tags
        end
      end
    end
  end
end
