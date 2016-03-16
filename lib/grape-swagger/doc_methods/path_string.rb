module GrapeSwagger
  module DocMethods
    class PathString
      class << self
        def build(path, options = {})
          # always removing format
          path.sub!(/\(\.\w+?\)$/, '')
          path.sub!('(.:format)', '')

          # ... format path params
          path.gsub!(/:(\w+)/, '{\1}')

          # set item from path, this could be used for the definitions object
          item = path.gsub(%r{/{(.+?)}}, '').split('/').last.singularize.underscore.camelize || 'Item'

          if options[:version] && options[:add_version]
            path.sub!('{version}', options[:version])
          else
            path.sub!('/{version}', '')
          end

          path = "#{GrapeSwagger::DocMethods::OptionalObject.build(:base_path, options)}#{path}" if options[:add_base_path]

          [item, path.start_with?('/') ? path : "/#{path}"]
        end
      end
    end
  end
end
