module GrapeSwagger
  module DocMethods
    class TagNameDescription
      class << self
        def build(paths)
          paths.values.each_with_object([]) do |path, memo|
            tags = path.values.first[:tags]
            next if tags.nil?
            tags.each do |tag|
              memo << {
                name: tag,
                description: "Operations about #{tag.pluralize}"
              }
            end
          end.uniq
        end
      end
    end
  end
end
