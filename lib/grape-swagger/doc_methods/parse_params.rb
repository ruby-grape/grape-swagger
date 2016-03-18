module GrapeSwagger
  module DocMethods
    class ParseParams
      class << self
        def call(param, value, route)
          @array_items = {}
          path = route.route_path
          method = route.route_method

          additional_documentation = value.is_a?(Hash) ? value[:documentation] : nil
          data_type = GrapeSwagger::DocMethods::DataType.call(value)

          if additional_documentation && value.is_a?(Hash)
            value = additional_documentation.merge(value)
          end

          description          = value.is_a?(Hash) ? value[:desc] || value[:description] : nil
          required             = value.is_a?(Hash) ? value[:required] : false
          default_value        = value.is_a?(Hash) ? value[:default] : nil
          example              = value.is_a?(Hash) ? value[:example] : nil
          is_array             = value.is_a?(Hash) ? (value[:is_array] || false) : false
          values               = value.is_a?(Hash) ? value[:values] : nil
          name                 = (value.is_a?(Hash) && value[:full_name]) || param
          enum_or_range_values = parse_enum_or_range_values(values)

          value_type = { value: value, data_type: data_type, path: path }

          parsed_params = {
            in:            param_type(value_type, param, method, is_array),
            name:          name,
            description:   description,
            type:          data_type,
            required:      required
          }

          if GrapeSwagger::DocMethods::DataType::PRIMITIVE_MAPPINGS.key?(data_type)
            parsed_params[:type], parsed_params[:format] = GrapeSwagger::DocMethods::DataType::PRIMITIVE_MAPPINGS[data_type]
          end

          parsed_params[:items] = @array_items if @array_items.present?

          parsed_params[:defaultValue] = example if example
          parsed_params[:defaultValue] = default_value if default_value && example.blank?

          parsed_params.merge!(enum_or_range_values) if enum_or_range_values
          parsed_params
        end

        def primitive?(type)
          %w(object integer long float double string byte boolean date datetime).include? type.to_s.downcase
        end

        private

        def param_type(value_type, param, method, is_array)
          # TODO: use `value_type.dig():value, :documentation, :param_type)` instead req ruby2.3
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
              primitive?(value_type[:data_type]) ? 'formData' : 'body'
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
