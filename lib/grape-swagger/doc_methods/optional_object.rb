# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    class OptionalObject
      class << self
        def build(key, options, request = nil)
          if options[key]
            return evaluate(key, options, request) if options[key].is_a?(Proc)

            options[key]
          else
            request.send(default_values[key])
          end
        end

        def evaluate(key, options, request)
          options[key].arity.zero? ? options[key].call : options[key].call(request)
        end

        def default_values
          {
            host: 'host_with_port',
            base_path: 'script_name'
          }
        end
      end
    end
  end
end
