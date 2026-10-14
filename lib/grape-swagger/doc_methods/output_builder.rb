# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    # Builds the Swagger 2.0 document (info, tags, paths, definitions) from the documented routes
    module OutputBuilder
      class << self
        def build(combi_routes, endpoint, target_class, options)
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

        private

        def tags_from(paths, options)
          tags = GrapeSwagger::DocMethods::TagNameDescription.build(paths)
          GrapeSwagger::DocMethods::RouteRules.merge_tags(tags, options[:tags])
        end
      end
    end
  end
end
