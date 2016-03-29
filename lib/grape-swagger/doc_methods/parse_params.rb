module GrapeSwagger
  module DocMethods
    class ParseParams
      class << self
        def call(param, settings, route)
          @array_items = {}
          path = route.route_path
          method = route.route_method

          data_type = GrapeSwagger::DocMethods::DataType.call(settings)
          additional_documentation = settings[:documentation]
          if additional_documentation
            settings = additional_documentation.merge(settings)
          end

          default_value        = settings[:default] || nil
          example              = settings[:example] || nil
          values               = settings[:values] || nil
          enum_or_range_values = parse_enum_or_range_values(values)

          value_type = { value: settings, data_type: data_type, path: path }

          parsed_params = {
            in:            param_type(value_type, param, method),
            name:          settings[:full_name] || param,
            description:   settings[:desc] || settings[:description] || nil,
            required:      settings[:required] || false
          }

          if GrapeSwagger::DocMethods::DataType.primitive?(data_type)
            data = GrapeSwagger::DocMethods::DataType.mapping(data_type)
            parsed_params[:type], parsed_params[:format] = data
          else
            parsed_params[:type] = data_type
          end

          if @array_items.present?
            parsed_params[:items] = @array_items
            parsed_params[:type] = 'array'
            parsed_params.delete(:format)
          end

          parsed_params[:default] = example if example
          parsed_params[:default] = default_value if default_value && example.blank?

          parsed_params.merge!(enum_or_range_values) if enum_or_range_values
          parsed_params
        end

        private

        def param_type(value_type, param, method)
          # TODO: use `value_type.dig():value, :documentation, :param_type)` instead, req ruby2.3
          #
          if value_type[:value][:is_array]
            if value_type[:value][:documentation].present?
              param_type = value_type[:value][:documentation][:param_type]
              type = GrapeSwagger::DocMethods::DataType.mapping(value_type[:value][:documentation][:type])
            end
            @array_items = { 'type' => type || value_type[:data_type] }

            param_type || 'formData'
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
