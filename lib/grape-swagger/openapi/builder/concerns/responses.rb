# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds OpenAPI responses from Grape route configuration
      module ResponseBuilder # rubocop:disable Metrics/ModuleLength
        def build_operation_responses(operation, route)
          codes = build_response_codes(route)

          codes.each do |code_info|
            response = build_response(code_info, route)
            operation.add_response(code_info[:code], response)
          end
        end

        private

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
          entity = route.options[:default_response]
          return [] if entity.nil?

          default_code = { code: 'default', message: 'Default Response' }
          if entity.is_a?(Hash)
            default_code[:message] = entity[:message] || default_code[:message]
            default_code[:model] = entity[:model] if entity[:model]
          else
            default_code[:model] = entity
          end

          [default_code]
        end

        def success_code?(code)
          status = code.is_a?(Array) ? code.first : code[:code]
          status.between?(200, 299)
        end

        def normalize_code(code)
          if code.is_a?(Array)
            { code: code[0], message: code[1], model: code[2], examples: code[3], headers: code[4] }
          else
            code
          end
        end

        def build_success_codes(route)
          entity = @current_entity

          return entity.map { |e| success_code_from_entity(route, e) } if entity.is_a?(Array)

          [success_code_from_entity(route, entity)]
        end

        def success_code_from_entity(route, entity)
          default_code = GrapeSwagger::DocMethods::StatusCodes.get[route.request_method.downcase.to_sym].dup

          if entity.is_a?(Hash)
            default_code[:code] = entity[:code] if entity[:code]
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

          return OpenAPI::Schema.new(type: 'array', items: schema) if route.options[:is_array] || code_info[:is_array]

          schema
        end

        def add_response_headers(response, code_info)
          code_info[:headers]&.each do |name, header_info|
            response.headers[name] = OpenAPI::Header.new(
              name: name,
              description: header_info[:description],
              type: header_info[:type],
              format: header_info[:format]
            )
          end
        end
      end
    end
  end
end
