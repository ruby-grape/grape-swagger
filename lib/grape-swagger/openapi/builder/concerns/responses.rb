# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds OpenAPI responses from Grape route configuration
      module ResponseBuilder # rubocop:disable Metrics/ModuleLength
        WARNED_STATUSES = Set.new
        WARNED_STATUSES_LOCK = Mutex.new

        def build_operation_responses(operation, route)
          codes = build_response_codes(route)

          codes.each do |code_info|
            next if unknown_status?(code_info[:code])

            response = build_response(code_info, route)
            operation.add_response(code_info[:code], response)
          end
        end

        private

        # A symbol Rack could not resolve (e.g. a typo) would be an invalid responses key.
        def unknown_status?(code)
          return false unless code.is_a?(Symbol)

          warn_unknown_status(code, 'the response is skipped')
          true
        end

        # Warns once per symbol; documentation is rebuilt on every request, possibly from several threads.
        def warn_unknown_status(code, outcome)
          return unless WARNED_STATUSES_LOCK.synchronize { WARNED_STATUSES.add?(code) }

          warn "grape-swagger: unknown response status #{code.inspect}; #{outcome}"
        end

        def build_response_codes(route)
          if route.http_codes.is_a?(Array) && route.http_codes.any? { |c| success_code?(c) }
            route.http_codes.map { |c| normalize_code(c) }
          else
            success_codes = build_success_codes(route)
            default_codes = build_default_codes(route)
            failure_codes = (route.http_codes || route.options[:failure] || []).map { |c| normalize_code(c) }
            success_codes + default_codes + failure_codes
          end
        end

        def build_default_codes(route)
          [GrapeSwagger::DocMethods::RouteRules.default_response_code(route)].compact
        end

        def success_code?(code)
          status = status_code(code.is_a?(Array) ? code.first : code[:code])
          status.is_a?(Integer) && status.between?(200, 299)
        end

        def normalize_code(code)
          if code.is_a?(Array)
            { code: status_code(code[0]), message: code[1], model: code[2], examples: code[3], headers: code[4] }
          else
            code.merge(code: status_code(code[:code]))
          end
        end

        # Symbolic statuses such as :created or :not_found become their HTTP code.
        def status_code(code)
          return code unless code.is_a?(Symbol)

          Rack::Utils.status_code(code)
        rescue ArgumentError
          code
        end

        # An unknown success status falls back to the method's default so the response is not lost.
        def success_status(code, default)
          resolved = status_code(code)
          return resolved unless resolved.is_a?(Symbol)

          warn_unknown_status(resolved, "using the default success status #{default}")
          default
        end

        def build_success_codes(route)
          entity = @current_entity

          return entity.map { |e| success_code_from_entity(route, e) } if entity.is_a?(Array)

          [success_code_from_entity(route, entity)]
        end

        def success_code_from_entity(route, entity)
          default_code = GrapeSwagger::DocMethods::StatusCodes.get[route.request_method.downcase.to_sym].dup

          if entity.is_a?(Hash)
            default_code[:code] = success_status(entity[:code], default_code[:code]) if entity[:code]
            default_code[:model] = entity[:model] if entity[:model]
            default_code[:headers] = entity[:headers] if entity[:headers]
            default_code[:is_array] = entity[:is_array] if entity[:is_array]
            default_code[:message] =
              entity[:message] || route.description || default_code[:message].sub('{item}', @current_item)
          elsif entity
            default_code[:model] = entity
            default_code[:message] = route.description || default_code[:message].sub('{item}', @current_item)
          else
            default_code[:message] = route.description || default_code[:message].sub('{item}', @current_item)
          end

          if route.request_method == 'DELETE' && default_code[:model].nil? && default_code[:code] == 200
            default_code[:code] = 204
          end

          default_code
        end

        def build_response(code_info, route)
          response = OpenAPI::Response.new
          response.status_code = code_info[:code].to_s
          response.description = code_info[:message] || ''

          add_response_content(response, code_info, route)
          add_response_headers(response, code_info)

          response
        end

        def add_response_content(response, code_info, route)
          return add_file_response_content(response) if file_response?(code_info[:model])
          return if code_info[:model] == ''

          model_name = resolve_response_model_name(code_info)
          return unless model_name && @definitions[model_name]

          schema = build_response_schema(model_name, route, code_info)
          build_produces(route).each { |content_type| response.add_media_type(content_type, schema: schema) }
        end

        def add_file_response_content(response)
          schema = OpenAPI::Schema.new(type: 'string', format: 'binary')
          response.add_media_type('application/octet-stream', schema: schema)
        end

        def resolve_response_model_name(code_info)
          if code_info[:model]
            expose_params_from_model(code_info[:model])
          elsif @definitions[@current_item]
            @current_item
          end
        end

        def build_response_schema(model_name, route, code_info)
          schema = OpenAPI::Schema.new
          schema.canonical_name = model_name

          is_array = route.options[:is_array] || code_info[:is_array]
          schema = OpenAPI::Schema.new(type: 'array', items: schema) if is_array
          return schema unless root_applicable?(code_info[:code])

          wrap_in_root(schema, model_name, route)
        end

        def root_applicable?(code)
          code.to_s == 'default' || code.to_i < 300
        end

        # Mirrors the 2.0 generator: `route_setting :swagger, root:` or the `add_root` option wraps the schema.
        def wrap_in_root(schema, model_name, route)
          root = route.settings.dig(:swagger, :root)
          # Like 2.0, any truthy `add_root` means "use the default root name".
          root = options[:add_root] ? true : false if root.nil?
          return schema unless root

          unless root.is_a?(String) || root.is_a?(Symbol)
            root = model_name.underscore
            root = root.pluralize if route.options[:is_array]
          end

          OpenAPI::Schema.new(type: 'object').tap { |wrapper| wrapper.add_property(root.to_s, schema) }
        end

        def add_response_headers(response, code_info)
          code_info[:headers]&.each do |name, header_info|
            response.headers[name] = build_response_header(name, header_info)
          end
        end

        def build_response_header(name, header_info)
          header = OpenAPI::Header.new(
            name: name,
            description: header_info[:description],
            type: header_info[:type],
            format: header_info[:format],
            example: header_info[:example]
          )
          items = header_info[:items]
          header.items = items.is_a?(Hash) ? OpenAPI::Schema.new(type: items[:type], format: items[:format]) : items
          # OAS 3 headers only allow the `simple` style, which is what `csv` means.
          if header_info[:collectionFormat].to_s == 'csv'
            header.style = 'simple'
            header.explode = false
          end
          header
        end
      end
    end
  end
end
