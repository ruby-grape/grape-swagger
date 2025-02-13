# frozen_string_literal: true

require 'active_support/core_ext/hash/deep_merge'

module GrapeSwagger
  module DocMethods
    class MoveParams
      class << self
        attr_accessor :definitions

        def can_be_moved?(http_verb, params)
          move_methods.include?(http_verb) && includes_body_param?(params)
        end

        def to_definition(path, params, route, definitions)
          @definitions = definitions
          unify!(params)

          params_to_move = movable_params(params)

          params << parent_definition_of_params(params_to_move, path, route)

          params
        end

        private

        def parent_definition_of_params(params, path, route)
          definition_name = OperationId.build(route, path)
          # NOTE: Parent definition is always object
          @definitions[definition_name] = object_type
          definition = @definitions[definition_name]
          move_params_to_new(definition, params)

          definition[:description] = route.description if route.try(:description)

          build_body_parameter(definition_name, route.options)
        end

        def move_params_to_new(definition, params)
          params, nested_params = params.partition { |x| !x[:name].to_s.include?('[') }
          params.each do |param|
            property = param[:name]

            param_properties, param_required = build_properties([param])
            add_properties_to_definition(definition, param_properties, param_required)
            related_nested_params, nested_params = nested_params.partition { |x| x[:name].start_with?("#{property}[") }
            prepare_nested_names(property, related_nested_params)

            next if related_nested_params.blank?

            nested_definition = if should_expose_as_array?([param])
                                  move_params_to_new(array_type, related_nested_params)
                                else
                                  move_params_to_new(object_type, related_nested_params)
                                end
            if definition.key?(:items)
              definition[:items][:properties][property.to_sym].deep_merge!(nested_definition)
            else
              definition[:properties][property.to_sym].deep_merge!(nested_definition)
            end
          end
          definition
        end

        def build_properties(params)
          properties = {}
          required = []

          params.each do |param|
            name = param[:name].to_sym

            properties[name] = if should_expose_as_array?([param])
                                 document_as_array(param)
                               else
                                 document_as_property(param)
                               end
            add_extension_properties(properties[name], param)

            required << name if deletable?(param) && param[:required]
          end

          [properties, required]
        end

        def document_as_array(param)
          {}.tap do |property|
            property[:type] = 'array'
            property[:description] = param.delete(:description) unless param[:description].nil?
            property[:example] = param.delete(:example) unless param[:example].nil?
            property[:items] = document_as_property(param)[:items]
          end
        end

        def add_extension_properties(definition, values)
          values.each do |key, value|
            definition[key] = value if key.start_with?('x-')
          end
        end

        def document_as_property(param)
          property_keys.each_with_object({}) do |x, memo|
            next unless param.key?(x)

            value = param[x]
            if x == :type && @definitions[value].present?
              memo['$ref'] = "#/definitions/#{value}"
            else
              memo[x] = value
            end
          end
        end

        def movable_params(params)
          to_delete = params.each_with_object([]) { |x, memo| memo << x if deletable?(x) }
          delete_from(params, to_delete)

          to_delete
        end

        def delete_from(params, to_delete)
          to_delete.each { |x| params.delete(x) }
        end

        def add_properties_to_definition(definition, properties, required)
          if definition.key?(:items)
            definition[:items][:properties].deep_merge!(properties)
            add_to_required(definition[:items], required)
          else
            definition[:properties].deep_merge!(properties)
            add_to_required(definition, required)
          end
        end

        def add_to_required(definition, value)
          return if value.blank?

          definition[:required] ||= []
          definition[:required].push(*value)
        end

        def build_body_parameter(name, options)
          {}.tap do |x|
            x[:name] = options[:body_name] || name
            x[:in] = 'body'
            x[:required] = true
            x[:schema] = { '$ref' => "#/definitions/#{name}" }
          end
        end

        def build_definition(name, params)
          @definitions[name] = should_expose_as_array?(params) ? array_type : object_type

          name
        end

        def array_type
          { type: 'array', items: { type: 'object', properties: {} } }
        end

        def object_type
          { type: 'object', properties: {} }
        end

        def prepare_nested_names(property, params)
          params.each { |x| x[:name] = x[:name].sub(property.to_s, '').sub('[', '').sub(']', '') }
        end

        def unify!(params)
          params.each { |x| x[:in] = x.delete(:param_type) if x[:param_type] }
          params.each { |x| x[:in] = 'body' if x[:in] == 'formData' } if includes_body_param?(params)
        end

        def parse_model(ref)
          parts = ref.split('/')
          parts.last.include?('{') ? parts[0..-2].join('/') : parts[0..-1].join('/')
        end

        def property_keys
          %i[type format description minimum maximum items enum default additional_properties additionalProperties
             example]
        end

        def deletable?(param)
          param[:in] == 'body'
        end

        def move_methods
          [:delete, :post, :put, :patch, 'DELETE', 'POST', 'PUT', 'PATCH']
        end

        def includes_body_param?(params)
          params.any? { |x| x[:in] == 'body' || x[:param_type] == 'body' }
        end

        def should_expose_as_array?(params)
          should_exposed_as(params) == 'array'
        end

        def should_exposed_as(params)
          params.any? { |x| x[:type] && x[:type] != 'array' } ? 'object' : 'array'
        end
      end
    end
  end
end
