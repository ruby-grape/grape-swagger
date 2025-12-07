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
          operation.tags = route.options.fetch(:tags, build_tags_for_route(route, path))
          operation.security = route.options[:security] if route.options.key?(:security)
          operation.produces = build_produces(route)
          operation.consumes = build_consumes(route)

          build_operation_parameters(operation, route, path)
          build_operation_responses(operation, route)
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
          return ['application/octet-stream'] if file_response?(route.options[:success]) &&
                                                 !route.options[:produces].present?

          format = options[:produces] || options[:format]
          mime_types = GrapeSwagger::DocMethods::ProducesConsumes.call(format)

          route_mime_types = %i[formats content_types produces].filter_map do |producer|
            possible = route.options[producer]
            GrapeSwagger::DocMethods::ProducesConsumes.call(possible) if possible.present?
          end.flatten.uniq

          route_mime_types.presence || mime_types
        end

        def build_consumes(route)
          return unless %i[post put patch].include?(route.request_method.downcase.to_sym)

          format = options[:consumes] || options[:format]
          GrapeSwagger::DocMethods::ProducesConsumes.call(
            route.settings.dig(:description, :consumes) || format
          )
        end

        def build_tags_for_route(route, path)
          version = GrapeSwagger::DocMethods::Version.get(route)
          version = Array(version)
          prefix = route.prefix.to_s.split('/').reject(&:empty?)

          Array(
            path.split('{')[0].split('/').reject(&:empty?).delete_if do |i|
              prefix.include?(i) || version.map(&:to_s).include?(i)
            end.first
          ).presence
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
