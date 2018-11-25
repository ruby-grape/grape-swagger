# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    class ParseParams
      class << self
        def call(param, settings, path, route, definitions)
          method = route.request_method
          additional_documentation = settings.fetch(:documentation, {})
          settings.merge!(additional_documentation)
          data_type = DataType.call(settings)

          value_type = settings.merge(data_type: data_type, path: path, param_name: param, method: method)

          # required properties
          @parsed_param = {
            in:   param_type(value_type),
            name: settings[:full_name] || param
          }

          # optional properties
          document_description(settings)
          document_type_and_format(settings, data_type)
          document_array_param(value_type, definitions) if value_type[:is_array]
          document_default_value(settings) unless value_type[:is_array]
          document_range_values(settings) unless value_type[:is_array]
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

        def document_type_and_format(settings, data_type)
          @parsed_param[:schema] = {}
          if DataType.primitive?(data_type)
            data = DataType.mapping(data_type)
            @parsed_param[:schema][:type], @parsed_param[:schema][:format] = data
          else
            @parsed_param[:schema][:type] = data_type
          end
          @parsed_param[:schema][:format] = settings[:format] if settings[:format].present?
        end

        def document_array_param(value_type, definitions)
          if value_type[:documentation].present?
            param_type = value_type[:documentation][:param_type]
            doc_type = value_type[:documentation][:type]
            type = DataType.mapping(doc_type) if doc_type && !DataType.request_primitive?(doc_type)
            collection_format = value_type[:documentation][:collectionFormat]
          end

          param_type ||= value_type[:param_type]

          array_items = {}
          if definitions[value_type[:data_type]]
            array_items['$ref'] = "#/components/schemas/#{@parsed_param[:type]}"
          else
            array_items[:type] = type || @parsed_param[:schema][:type] == 'array' ? 'string' : @parsed_param[:schema][:type]
          end
          array_items[:format] = @parsed_param.delete(:format) if @parsed_param[:format]

          values = value_type[:values] || nil
          enum_or_range_values = parse_enum_or_range_values(values)
          array_items.merge!(enum_or_range_values) if enum_or_range_values

          array_items[:default] = value_type[:default] if value_type[:default].present?

          @parsed_param[:in] = param_type || 'formData'
          @parsed_param[:items] = array_items
          @parsed_param[:schema][:type] = 'array'
          @parsed_param[:collectionFormat] = collection_format if DataType.collections.include?(collection_format)
        end

        def param_type(value_type)
          param_type = value_type[:param_type] || value_type[:in]
          if value_type[:path].include?("{#{value_type[:param_name]}}")
            'path'
          elsif param_type
            param_type
          elsif %w[POST PUT PATCH].include?(value_type[:method])
            DataType.request_primitive?(value_type[:data_type]) ? 'formData' : 'body'
          else
            'query'
          end
        end

        def parse_enum_or_range_values(values)
          case values
          when Proc
            parse_enum_or_range_values(values.call) if values.parameters.empty?
          when Range
            if values.first.is_a?(Numeric)
              parse_range_values(values)
            else
              { enum: values.to_a }
            end
          else
            if values.respond_to? :each
              { enum: values }
            else
              { enum: [values] }
            end
          end
        end

        def parse_range_values(values)
          { minimum: values.first, maximum: values.last }
        end
      end
    end
  end
end
