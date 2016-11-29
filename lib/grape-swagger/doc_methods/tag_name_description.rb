# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    class TagNameDescription
      class << self
        def build(paths)
          paths.values.each_with_object([]) do |path, memo|
            tags = path.values.first[:tags]
            next if tags.nil?

            case tags
            when String
              memo << build_memo(tags)
            when Array
              path.values.first[:tags].each do |tag|
                memo << build_memo(tag)
              end
            end
          end.uniq
        end

        private

        def build_memo(tag)
          {
            name: tag,
            description: "Operations about #{tag.pluralize}"
          }
        end
      end
    end
  end
end
