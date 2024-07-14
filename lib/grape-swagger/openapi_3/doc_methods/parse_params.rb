# frozen_string_literal: true

require 'grape-swagger/doc_methods/parse_params'
require 'grape-swagger/endpoint/info_object_builder'

module GrapeSwagger
  module DocMethods
    class OpenAPIParseParams < GrapeSwagger::DocMethods::ParseParams
      class << self
        private

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
            array_items['$ref'] = "#/components/schemas/#{@parsed_param[:schema][:type]}"
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
            if values
              if values.respond_to? :each
                { enum: values }
              else
                { enum: [values] }
              end
            end
          end
        end
      end
    end
  end
end
