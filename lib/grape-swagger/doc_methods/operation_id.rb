module GrapeSwagger
  module DocMethods
    class OperationId
      class << self
        def build(route, path = nil)
          if route.options[:nickname]
            operation_id = route.options[:nickname]
          else
            verb = route.request_method.to_s.downcase

            operation = manipulate(path) unless path.nil?

            operation_id = "#{verb}#{operation}"
          end

          operation_id
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
