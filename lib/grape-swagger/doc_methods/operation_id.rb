module GrapeSwagger
  module DocMethods
    class OperationId
      class << self
        def build(method, path = nil)
          verb = method.to_s.downcase

          unless path.nil?
            operation = path.split('/').map(&:capitalize).join
            operation.gsub!(/\-(\w)/, &:upcase).delete!('-') if operation.include?('-')
            operation.gsub!(/\_(\w)/, &:upcase).delete!('_') if operation.include?('_')
            if path.include?('{')
              operation.gsub!(/\{(\w)/, &:upcase)
              operation.delete!('{').delete!('}')
            end
          end

          "#{verb}#{operation}"
        end
      end
    end
  end
end
