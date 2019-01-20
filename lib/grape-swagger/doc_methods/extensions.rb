# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    class Extensions
      class << self
        def add(path, definitions, route)
          @route = route

          description = route.settings[:description]
          add_extension_to(path[method], extension(description)) if description && extended?(description, :x)

          settings = route.settings
          add_extensions_to_operation(settings, path, route) if settings && extended?(settings, :x_operation)
          add_extensions_to_path(settings, path) if settings && extended?(settings, :x_path)
          add_extensions_to_definition(settings, path, definitions) if settings && extended?(settings, :x_def)
        end

        def add_extensions_to_root(settings, object)
          add_extension_to(object, extension(settings)) if extended?(settings, :x)
        end

        def add_extensions_to_info(settings, info)
          add_extension_to(info, extension(settings)) if extended?(settings, :x)
        end

        def add_extensions_to_operation(settings, path, route)
          add_extension_to(path[route.request_method.downcase.to_sym], extension(settings, :x_operation))
        end

        def add_extensions_to_path(settings, path)
          add_extension_to(path, extension(settings, :x_path))
        end

        def add_extensions_to_definition(settings, path, definitions)
          def_extension = extension(settings, :x_def)

          if def_extension[:x_def].is_a?(Array)
            def_extension[:x_def].each { |extension| setup_definition(extension, path, definitions) }
          else
            setup_definition(def_extension[:x_def], path, definitions)
          end
        end

        def setup_definition(def_extension, path, definitions)
          return unless def_extension.key?(:for)

          status = def_extension[:for]

          definition = find_definition(status, path)
          add_extension_to(definitions[definition], x_def: def_extension)
        end

        def find_definition(status, path)
          response = path[method][:responses][status]
          return if response.nil?

          # Swagger 2
          if response[:schema]
            return response[:schema]['$ref'].split('/').last if response[:schema].key?('$ref')
            return response[:schema]['items']['$ref'].split('/').last if response[:schema].key?('items')
          end

          # OpenAPI 3
          response[:content].each do |_,v|
            return v[:schema]['$ref'].split('/').last if v[:schema].key?('$ref')
            return v[:schema]['items']['$ref'].split('/').last if v[:schema].key?('items')
          end
        end

        def add_extension_to(part, extensions)
          return if part.nil?

          concatenate(extensions).each do |key, value|
            part[key] = value unless key.start_with?('x-for')
          end
        end

        def concatenate(extensions)
          result = {}

          extensions.each_value do |extension|
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

        def method(*args)
          # We're shadowing Object.method(:symbol) here so we provide
          # a compatibility layer for code that introspects the methods
          # of this class
          return super if args.size.positive?

          @route.request_method.downcase.to_sym
        end
      end
    end
  end
end
