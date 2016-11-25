module GrapeSwagger
  module DocMethods
    class PathString
      class << self
        def build(route, options = {})
          path = route.path
          # always removing format
          path.sub!(/\(\.\w+?\)$/, '')
          path.sub!('(.:format)', '')

          # ... format path params
          path.gsub!(/:(\w+)/, '{\1}')

          # set item from path, this could be used for the definitions object
          item = path.gsub(%r{/{(.+?)}}, '').split('/').last.singularize.underscore.camelize || 'Item'

          if route.version && options[:add_version]
            version = route.version
            # for grape version 0.14.0..0.16.2, the version can be a string like '[:v1, :v2]'
            # for grape version bigger than 0.16.2, the version can be a array like [:v1, :v2]
            version = version.first while version.is_a?(Array)
            # eval('[:v1, :v2]') for grape lower than 0.17
            version = eval(version) if version.is_a?(String) && version.start_with?('[') && version.end_with?(']')
            version = version.first while version.is_a?(Array)
            path.sub!('{version}', version.to_s)
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
