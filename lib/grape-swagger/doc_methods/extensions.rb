module GrapeSwagger
  module DocMethods
    class Extensions
      class << self
        def add(path, definitions, route)
          @route = route
          description = route.settings[:description]
          add_extension_to(path[method], extension(description)) if description && extended?(description, :x)

          settings = route.settings
          add_extensions_to_path(settings, path) if settings && extended?(settings, :x_path)
          add_extensions_to_definition(settings, path, definitions) if settings && extended?(settings, :x_def)
        end

        def add_extensions_to_path(settings, path)
          add_extension_to(path, extension(settings, :x_path))
        end

        def add_extensions_to_definition(settings, path, definitions)
          def_extension = extension(settings, :x_def)

          if def_extension[:x_def].is_a?(Array)
            def_extension[:x_def].each do |extension|
              next unless extension.key?(:for)
              status = extension.delete(:for)
              definition = find_definition(status, path)
              add_extension_to(definitions[definition], x_def: extension)
            end
          else
            return unless def_extension[:x_def].key?(:for)
            status = def_extension[:x_def].delete(:for)
            definition = find_definition(status, path)
            add_extension_to(definitions[definition], def_extension)
          end
        end

        def find_definition(status, path)
          response = path[method][:responses][status]

          response[:schema]['$ref'].split('/').last
        end

        def add_extension_to(part, extensions)
          concatenate(extensions).each do |key, value|
            part[key] = value
          end
        end

        def concatenate(extensions)
          result = {}

          extensions.values.each do |extension|
            extension.each do |key, value|
              result["x-#{key}"] = value
            end
          end

          result
        end

        def extended?(part, identifier = :x)
          !extension(part, identifier).empty?
        end

        def extension(part, identifier = :x)
          part.select { |x| x == identifier }
        end

        def method
          @route.request_method.downcase.to_sym
        end
      end
    end
  end
end
