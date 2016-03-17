module GrapeSwagger
  module DocMethods
    class OptionalObject
      class << self
        def build(key, options, request = nil)
          if options[key]
            options[key].is_a?(Proc) ? options[key].call : options[key]
          else
            request
          end
        end
      end
    end
  end
end
