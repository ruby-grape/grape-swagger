module GrapeSwagger
  module DocMethods
    class ParseParams
      class << self
        def call(param, settings, route)
          path = route.path
          method = route.request_method

          additional_documentation = settings.fetch(:documentation, {})
          settings.merge!(additional_documentation)
          data_type = GrapeSwagger::DocMethods::DataType.call(settings)

          value_type = settings.merge(data_type: data_type, path: path, param_name: param, method: method)

          # required properties
          @parsed_param = {
            in:   param_type(value_type),
            name: settings[:full_name] || param
          }

          # optional properties
          document_description(settings)
          document_type_and_format(data_type)
          document_array_param(value_type)
          document_default_value(settings)
          document_range_values(settings)
          document_required(settings)

          @parsed_param
        end

        private

        def document_description(settings)
          description = settings[:desc] || settings[:description]
          @parsed_param[:description] = description if description
        end

        def document_required(settings)
          @parsed_param[:required] = settings[:required] || false
          @parsed_param[:required] = true if @parsed_param[:in] == 'path'
        end

        def document_range_values(settings)
          values               = settings[:values] || nil
          enum_or_range_values = parse_enum_or_range_values(values)
          @parsed_param.merge!(enum_or_range_values) if enum_or_range_values
        end

        def document_default_value(settings)
          @parsed_param[:default] = settings[:default] if settings[:default].present?
        end

        def document_type_and_format(data_type)
          if GrapeSwagger::DocMethods::DataType.primitive?(data_type)
            data = GrapeSwagger::DocMethods::DataType.mapping(data_type)
            @parsed_param[:type], @parsed_param[:format] = data
          else
            @parsed_param[:type] = data_type
          end
        end

        def document_array_param(value_type)
          if value_type[:is_array]
            if value_type[:documentation].present?
              param_type = value_type[:documentation][:param_type]
              if (doc_type = value_type[:documentation][:type])
                type = GrapeSwagger::DocMethods::DataType.mapping(doc_type)
              end
            end
            array_items = { 'type' => type || value_type[:data_type] }

            @parsed_param[:in] = param_type || 'formData'
            @parsed_param[:items] = array_items
            @parsed_param[:type] = 'array'
            @parsed_param.delete(:format)
          end
        end

        def param_type(value_type)
          param_type = value_type[:param_type] || value_type[:in]
          if value_type[:path].include?("{#{value_type[:param_name]}}")
            'path'
          elsif param_type
            param_type
          elsif %w(POST PUT PATCH).include?(value_type[:method])
            GrapeSwagger::DocMethods::DataType.request_primitive?(value_type[:data_type]) ? 'formData' : 'body'
          else
            'query'
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
