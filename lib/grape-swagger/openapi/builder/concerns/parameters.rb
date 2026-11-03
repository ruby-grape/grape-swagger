# frozen_string_literal: true

require_relative 'param_schemas'

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds OpenAPI parameters from Grape route parameters
      module ParameterBuilder
        include ParamSchemaBuilder

        def build_operation_parameters(operation, route, path)
          raw_params = build_request_params(route)
          consumes = operation.consumes || @spec.consumes

          body_params = []
          form_entries = []

          raw_params.each do |name, param_options|
            next if hidden_parameter?(param_options)

            # `array_use_braces` adds a braced twin (`ids[]`) next to the bare name; like 2.0, emit only the braced one.
            next if raw_params.key?("#{name}[]")

            braced = name.to_s.end_with?('[]')
            name = name.to_s.gsub('[]', '')

            param = build_parameter(name, param_options, route, path, consumes)
            # Flat query/header/form fields keep the braces clients must send; JSON bodies and nested fields do not.
            param.name = "#{param.name}[]" if braced && !%w[path body].include?(param.location)
            is_nested = name.to_s.include?('[')

            case param.location
            when 'body'
              body_params << { name: name, options: param_options, param: param }
            when 'formData'
              if is_nested
                body_params << { name: name, options: param_options, param: param }
              else
                form_entries << { name: name, options: param_options, param: param }
              end
            else
              operation.add_parameter(param)
            end
          end

          if body_params.any?
            # Flat form fields declared next to nested ones belong in the same schema.
            build_request_body_from_params(operation, form_entries + body_params, consumes, route, path)
          elsif form_entries.any?
            build_request_body_from_form_data(operation, form_entries.map { |e| e[:param] }, consumes)
          end
        end

        private

        def build_request_params(route)
          GrapeSwagger.request_param_parsers.each_with_object({}) do |parser_klass, accum|
            params = parser_klass.parse(route, accum, options, @endpoint)
            accum.merge!(params.stringify_keys)
          end
        end

        def build_parameter(name, param_options, route, path, consumes)
          param = OpenAPI::Parameter.new
          param.name = param_options[:full_name] || name
          param.location = determine_param_location(name, param_options, route, path, consumes)
          param.description = param_options[:desc] || param_options[:description]
          param.required = param.location == 'path' || param_options[:required] || false
          param.schema = build_param_schema(param_options)
          param.collection_format = collection_format_for(param, param_options)
          param.deprecated = param_options[:deprecated] if param_options.key?(:deprecated)
          copy_param_extensions(param, param_options)
          param
        end

        # Like Swagger 2.0, only arrays carry a collectionFormat, and only a known one.
        def collection_format_for(param, param_options)
          format = (param_options[:documentation] || {})[:collectionFormat]
          format if param.schema.type == 'array' && GrapeSwagger::DocMethods::DataType.collections.include?(format)
        end

        def determine_param_location(name, param_options, route, path, consumes)
          return 'path' if path.include?("{#{name}}")

          doc = param_options[:documentation] || {}
          return doc[:param_type] if doc[:param_type]
          return doc[:in] if doc[:in]

          if %w[POST PUT PATCH].include?(route.request_method)
            # Normalize consumes to array (can be string like 'multipart/form-data')
            consumes_array = Array(consumes)
            consumes_array.any? { |c| c.to_s.include?('form') } ? 'formData' : 'body'
          else
            'query'
          end
        end

        def build_param_schema(param_options)
          schema = OpenAPI::Schema.new
          data_type = GrapeSwagger::DocMethods::DataType.call(param_options)
          apply_type_to_schema(schema, data_type, param_options)

          doc = param_options[:documentation] || {}
          # Support both documentation: { nullable: true } and x: { nullable: true } for backward compatibility
          schema.nullable = true if doc[:nullable] || doc.dig(:x, :nullable)

          example_source = [doc, param_options].find { |options| options.key?(:example) }
          schema.example = example_source[:example] if example_source

          if doc.key?(:additional_properties)
            target = schema.type == 'array' && schema.items ? schema.items : schema
            apply_additional_properties(target, doc[:additional_properties])
          end

          apply_constraints_to_schema(schema, param_options)
          schema
        end
      end
    end
  end
end
