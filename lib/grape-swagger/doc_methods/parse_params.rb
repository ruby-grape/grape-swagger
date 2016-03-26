module GrapeSwagger
  module DocMethods
    class ParseParams
      class << self
        def call(param, value, route)
          @array_items = {}
          path = route.route_path
          method = route.route_method

          data_type = GrapeSwagger::DocMethods::DataType.call(value)
          additional_documentation = value[:documentation]
          if additional_documentation
            value = additional_documentation.merge(value)
          end

          description          = value[:desc] || value[:description] || nil
          required             = value[:required] || false
          default_value        = value[:default] || nil
          example              = value[:example] || nil
          is_array             = value[:is_array] || false
          values               = value[:values] || nil
          name                 = value[:full_name] || param
          enum_or_range_values = parse_enum_or_range_values(values)

          value_type = { value: value, data_type: data_type, path: path }

          parsed_params = {
            in:            param_type(value_type, param, method, is_array),
            name:          name,
            description:   description,
            required:      required
          }

          if GrapeSwagger::DocMethods::DataType.primitive?(data_type)
            data = GrapeSwagger::DocMethods::DataType::PRIMITIVE_MAPPINGS[data_type]
            parsed_params[:type], parsed_params[:format] = data
          else
            parsed_params[:type] = data_type
          end

          parsed_params[:items] = @array_items if @array_items.present?

          parsed_params[:default] = example if example
          parsed_params[:default] = default_value if default_value && example.blank?

          parsed_params.merge!(enum_or_range_values) if enum_or_range_values
          parsed_params
        end

        private

        def param_type(value_type, param, method, is_array)
          # TODO: use `value_type.dig():value, :documentation, :param_type)` instead, req ruby2.3
          #
          if value_type[:value].is_a?(Hash) &&
             value_type[:value].key?(:documentation) &&
             value_type[:value][:documentation].key?(:param_type)

            if is_array
              @array_items = { 'type' => value_type[:data_type] }

              'array'
            end
          else
            case
            when value_type[:path].include?("{#{param}}")
              'path'
            when %w(POST PUT PATCH).include?(method)
              GrapeSwagger::DocMethods::DataType.request_primitive?(value_type[:data_type]) ? 'formData' : 'body'
            else
              'query'
            end
          end
        end

        def parse_enum_or_range_values(values)
          case values
          when Range
            parse_range_values(values) if values.first.is_a?(Integer)
          when Proc
            values_result = values.call
            if values_result.is_a?(Range) && values_result.first.is_a?(Integer)
              parse_range_values(values_result)
            else
              { enum: values_result }
            end
          else
            { enum: values } if values
          end
        end

        def parse_range_values(values)
          { minimum: values.first, maximum: values.last }
        end
      end
    end
  end
end
