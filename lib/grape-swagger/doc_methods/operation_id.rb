module GrapeSwagger
  module DocMethods
    class OperationId
      class << self
        def build(route, path = nil)
          verb = route.route_method.to_s.downcase

          operation = manipulate(path) unless path.nil?

          "#{verb}#{operation}"
        end

        def manipulate(path)
          operation = path.split('/').map(&:capitalize).join
          operation.gsub!(/\-(\w)/, &:upcase).delete!('-') if operation.include?('-')
          operation.gsub!(/\_(\w)/, &:upcase).delete!('_') if operation.include?('_')
          if path.include?('{')
            operation.gsub!(/\{(\w)/, &:upcase)
            operation.delete!('{').delete!('}')
          end

          operation
        end
      end
    end
  end
end
