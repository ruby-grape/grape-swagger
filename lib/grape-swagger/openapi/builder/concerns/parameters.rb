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
          form_data_params = []

          raw_params.each do |name, param_options|
            next if hidden_parameter?(param_options)

            param = build_parameter(name, param_options, route, path, consumes)
            is_nested = name.to_s.include?('[')

            case param.location
            when 'body'
              body_params << { name: name, options: param_options, param: param }
            when 'formData'
              if is_nested
                body_params << { name: name, options: param_options, param: param }
              else
                form_data_params << param
              end
            else
              operation.add_parameter(param)
            end
          end

          if body_params.any?
            build_request_body_from_params(operation, body_params, consumes, route, path)
          elsif form_data_params.any?
            build_request_body_from_form_data(operation, form_data_params, consumes)
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
          param.deprecated = param_options[:deprecated] if param_options.key?(:deprecated)
          copy_param_extensions(param, param_options)
          param
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
          schema.nullable = true if param_options[:allow_blank] || doc[:nullable]

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
