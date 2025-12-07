# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds OpenAPI Tag objects from operations and user configuration
      module TagBuilder
        private

        def build_tags
          all_tags = @spec.paths.each_value.flat_map do |path_item|
            path_item.operations.flat_map { |_method, operation| operation&.tags || [] }
          end

          all_tags.uniq.each do |tag_name|
            tag = OpenAPI::Tag.new(
              name: tag_name,
              description: "Operations about #{tag_name.to_s.pluralize}"
            )
            @spec.add_tag(tag)
          end

          # Merge with user-provided tags
          return unless options[:tags]

          user_tag_names = options[:tags].map { |t| t[:name] }
          @spec.tags.reject! { |t| user_tag_names.include?(t.name) }

          options[:tags].each do |tag_hash|
            tag = OpenAPI::Tag.new(
              name: tag_hash[:name],
              description: tag_hash[:description]
            )
            @spec.add_tag(tag)
          end
        end
      end
    end
  end
end
