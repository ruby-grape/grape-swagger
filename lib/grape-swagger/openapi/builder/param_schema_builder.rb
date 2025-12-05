# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds parameter schemas with type handling for OpenAPI
      module ParamSchemaBuilder # rubocop:disable Metrics/ModuleLength
        private

        def apply_additional_properties(schema, additional_props)
          case additional_props
          when true, false, Hash
            schema.additional_properties = additional_props
          when String
            schema.additional_properties = { type: additional_props.downcase }
          when Class
            apply_additional_properties_class(schema, additional_props)
          end
        end

        def apply_additional_properties_class(schema, klass)
          is_entity = begin
            klass < Grape::Entity
          rescue StandardError
            false
          end

          if is_entity
            model_name = expose_params_from_model(klass)
            schema.additional_properties = { canonical_name: model_name } if model_name
          else
            type_name = GrapeSwagger::DocMethods::DataType.call(type: klass)
            schema.additional_properties = { type: type_name }
          end
        end

        def apply_type_to_schema(schema, data_type, param_options)
          original_type = param_options[:type]
          element_class = extract_array_element_class(original_type)

          if element_class
            apply_array_entity_type(schema, element_class, param_options, data_type)
          elsif data_type == 'array' || param_options[:is_array]
            apply_array_type(schema, param_options, data_type)
          elsif GrapeSwagger::DocMethods::DataType.primitive?(data_type)
            apply_primitive_type(schema, data_type, param_options)
          elsif data_type == 'file'
            apply_file_type(schema)
          elsif %w[json JSON].include?(data_type)
            schema.type = 'object'
          elsif @definitions.key?(data_type)
            schema.canonical_name = data_type
          else
            apply_complex_type(schema, data_type, original_type)
          end
        end

        def apply_array_entity_type(schema, element_class, param_options, data_type)
          schema.type = 'array'
          if has_model_parser?(element_class)
            model_name = expose_params_from_model(element_class)
            items = OpenAPI::Schema.new
            items.canonical_name = model_name if model_name
            schema.items = items
          else
            schema.items = build_array_items_schema(param_options, data_type)
          end
        end

        def apply_array_type(schema, param_options, data_type)
          schema.type = 'array'
          schema.items = build_array_items_schema(param_options, data_type)
        end

        def apply_primitive_type(schema, data_type, param_options)
          type, format = GrapeSwagger::DocMethods::DataType.mapping(data_type)
          schema.type = type
          schema.format = param_options[:format] || format
        end

        def apply_file_type(schema)
          schema.type = 'string'
          schema.format = 'binary'
        end

        def apply_complex_type(schema, data_type, original_type)
          return if try_apply_class_type(schema, original_type)
          return if try_apply_string_class_type(schema, original_type)

          schema.type = data_type
        end

        def try_apply_class_type(schema, original_type)
          return false unless original_type.is_a?(Class)
          return false unless has_model_parser?(original_type)

          model_name = expose_params_from_model(original_type)
          schema.canonical_name = model_name if model_name
          true
        end

        def try_apply_string_class_type(schema, original_type)
          return false unless original_type.is_a?(String)
          return false if GrapeSwagger::DocMethods::DataType.primitive?(original_type)

          klass = Object.const_get(original_type)
          return false unless has_model_parser?(klass)

          model_name = expose_params_from_model(klass)
          schema.canonical_name = model_name if model_name
          true
        rescue NameError
          false
        end

        def has_model_parser?(klass)
          GrapeSwagger.model_parsers.find(klass)
        rescue StandardError
          false
        end

        def extract_array_element_class(type)
          return type.first if type.is_a?(Array) && type.first.is_a?(Class)

          if type.is_a?(String) && type =~ /\A\[(.+)\]\z/
            class_name = ::Regexp.last_match(1).strip
            begin
              return Object.const_get(class_name)
            rescue NameError
              return nil
            end
          end

          nil
        end

        def build_array_items_schema(param_options, data_type = nil)
          items = OpenAPI::Schema.new
          doc = param_options[:documentation] || {}

          item_type = if doc[:type]
                        GrapeSwagger::DocMethods::DataType.call(type: doc[:type])
                      elsif data_type && data_type != 'array'
                        data_type
                      else
                        'string'
                      end

          if GrapeSwagger::DocMethods::DataType.primitive?(item_type)
            type, format = GrapeSwagger::DocMethods::DataType.mapping(item_type)
            items.type = type
            items.format = format
          elsif item_type == 'file'
            items.type = 'string'
            items.format = 'binary'
          elsif @definitions.key?(item_type)
            items.canonical_name = item_type
          else
            items.type = item_type
          end

          items
        end

        def apply_constraints_to_schema(schema, param_options)
          values = param_options[:values]
          case values
          when Range
            schema.minimum = values.begin if values.begin.is_a?(Integer)
            schema.maximum = values.end if values.end.is_a?(Integer)
          when Array
            schema.enum = values
          when Proc
            result = values.call if values.parameters.empty?
            schema.enum = result if result.is_a?(Array)
          end

          schema.default = param_options[:default] if param_options.key?(:default)
          schema.min_length = param_options[:min_length] if param_options[:min_length]
          schema.max_length = param_options[:max_length] if param_options[:max_length]

          doc = param_options[:documentation] || {}
          schema.description = param_options[:desc] ||
                               param_options[:description] ||
                               doc[:desc] ||
                               doc[:description]
        end

        def copy_param_extensions(param, param_options)
          doc = param_options[:documentation] || {}

          doc.fetch(:x, {}).each do |key, value|
            param.extensions["x-#{key}"] = value
          end

          param_options.each do |key, value|
            param.extensions[key.to_s] = value if key.to_s.start_with?('x-')
          end
        end
      end
    end
  end
end
