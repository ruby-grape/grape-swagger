# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds OpenAPI Operation objects from Grape route definitions
      module OperationBuilder
        private

        def build_operation(route, path)
          operation = OpenAPI::Operation.new
          operation.operation_id = GrapeSwagger::DocMethods::OperationId.build(route, path)
          operation.summary = build_summary(route)
          operation.description = build_description(route)
          operation.deprecated = route.options[:deprecated] if route.options.key?(:deprecated)
          operation.tags = build_tags_for_route(route, path)
          operation.security = route.options[:security] if route.options.key?(:security)
          operation.consumes = build_consumes(route)

          add_operation_extensions(operation, route)

          operation
        end

        def build_summary(route)
          summary = route.options[:desc] if route.options.key?(:desc)
          summary = route.description if route.description.present? && route.options.key?(:detail)
          summary = route.options[:summary] if route.options.key?(:summary)
          summary
        end

        def build_description(route)
          description = route.description if route.description.present?
          description = route.options[:detail] if route.options.key?(:detail)
          description
        end

        def build_produces(route)
          GrapeSwagger::DocMethods::RouteRules.produces(route, options[:produces] || options[:format])
        end

        def build_consumes(route)
          GrapeSwagger::DocMethods::RouteRules.consumes(route, options[:consumes] || options[:format])
        end

        def build_tags_for_route(route, path)
          GrapeSwagger::DocMethods::RouteRules.tag_names(route, path)
        end

        def add_operation_extensions(operation, route)
          x_operation = route.settings[:x_operation]
          return unless x_operation

          x_operation.each do |key, value|
            operation.extensions["x-#{key}"] = value
          end
        end
      end
    end
  end
end
