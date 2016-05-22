module GrapeSwagger
  module DocMethods
    class PathString
      class << self
        def build(route, options = {})
          # always removing format
          route.path.sub!(/\(\.\w+?\)$/, '')
          route.path.sub!('(.:format)', '')

          # ... format path params
          route.path.gsub!(/:(\w+)/, '{\1}')

          # set item from path, this could be used for the definitions object
          item = route.path.gsub(%r{/{(.+?)}}, '').split('/').last.singularize.underscore.camelize || 'Item'

          if route.options[:version] && options[:add_version]
            route.path.sub!('{version}', route.options[:version].to_s)
          else
            route.path.sub!('/{version}', '')
          end

          route.path = "#{GrapeSwagger::DocMethods::OptionalObject.build(:base_path, options)}#{route.path}" if options[:add_base_path]

          [item, route.path.start_with?('/') ? route.path : "/#{route.path}"]
        end
      end
    end
  end
end
