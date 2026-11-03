# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds OpenAPI Tag objects from operations and user configuration
      module TagBuilder
        private

        def build_tags
          names = @spec.paths.each_value.flat_map do |path_item|
            path_item.operations.flat_map { |_method, operation| operation&.tags || [] }
          end.uniq

          derived = names.map { |name| GrapeSwagger::DocMethods::TagNameDescription.build_memo(name.to_s).merge(name: name) }
          GrapeSwagger::DocMethods::RouteRules.merge_tags(derived, options[:tags]).each do |tag_hash|
            @spec.add_tag(
              OpenAPI::Tag.new(
                name: tag_hash[:name],
                description: tag_hash[:description],
                external_docs: tag_hash[:externalDocs] || tag_hash[:external_docs]
              )
            )
          end
        end
      end
    end
  end
end
