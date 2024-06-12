# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    class PathString
      class << self
        def build(route, path, options = {})
          # always removing format
          path.sub!(/\(\.\w+?\)$/, '')
          path.sub!('(.:format)', '')

          # ... format path params
          path.gsub!(/:(\w+)/, '{\1}')

          # set item from path, this could be used for the definitions object
          path_name = path.gsub(%r{/{(.+?)}}, '').split('/').last
          item = path_name.present? ? path_name.singularize.underscore.camelize : 'Item'

          if route.version && options[:add_version]
            version = GrapeSwagger::DocMethods::Version.get(route)
            version = version.first while version.is_a?(Array)
            path.sub!('{version}', version.to_s)
          else
            path.sub!('/{version}', '')
          end

          path = "#{OptionalObject.build(:base_path, options)}#{path}" if options[:add_base_path]

          [item, path.start_with?('/') ? path : "/#{path}"]
        end

        def generate_optional_segments(path)
          # always removing format
          path.sub!(/\(\.\w+?\)$/, '')
          path.sub!('(.:format)', '')

          paths = []
          if path.match(/\(.+\)/)
            # recurse with included optional segment
            paths.concat(generate_optional_segments(path.sub(/\([^\)]+\)/, '')))
            # recurse with excluded optional segment
            paths.concat(generate_optional_segments(path.sub(/\(/, '').sub(/\)/, '')))
          else
            paths << path
          end
          paths
        end
      end
    end
  end
end
