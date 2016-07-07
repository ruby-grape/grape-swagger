module GrapeSwagger
  module DocMethods
    class MoveParams
      class << self
        attr_accessor :definitions

        def can_be_moved?(params, http_verb)
          move_methods.include?(http_verb) && includes_body_param?(params)
        end

        def to_definition(params, route, definitions)
          @definitions = definitions
          unify!(params)

          params_to_move = movable_params(params)
          params << parent_definition_of_params(params_to_move, route)

          params
        end

        def parent_definition_of_params(params, route)
          definition_name = GrapeSwagger::DocMethods::OperationId.manipulate(parse_model(route.path))
          referenced_definition = build_definition(definition_name, params, route.request_method.downcase)
          definition = @definitions[referenced_definition]

          move_params_to_new(definition, params)

          definition[:description] = route.description if route.respond_to?(:description)

          build_body_parameter(referenced_definition, definition_name)
        end

        def move_params_to_new(definition, params)
          params, nested_params = params.partition { |x| !x[:name].include?('[') }

          unless params.blank?
            properties, required = build_properties(params)
            add_properties_to_definition(definition, properties, required)
          end

          nested_properties = build_nested_properties(nested_params) unless nested_params.blank?
          add_properties_to_definition(definition, nested_properties, []) unless nested_params.blank?
        end

        def build_nested_properties(params, properties = {})
          property = params.bsearch { |x| x[:name].include?('[') }[:name].split('[').first

          nested_params, params = params.partition { |x| x[:name].start_with?(property) }
          prepare_nested_names(property, nested_params)

          recursive_call(properties, property, nested_params) unless nested_params.empty?
          build_nested_properties(params, properties) unless params.empty?

          properties
        end

        def recursive_call(properties, property, nested_params)
          if should_expose_as_array?(nested_params)
            properties[property] = { type: 'array', items: { type: 'object', properties: {}, required: [] } }
            move_params_to_new(properties[property][:items], nested_params)
          else
            properties[property] = { type: 'object', properties: {}, required: [] }
            move_params_to_new(properties[property], nested_params)
          end
        end

        private

        def movable_params(params)
          to_delete = params.each_with_object([]) { |x, memo| memo << x if deletable?(x) }
          delete_from(params, to_delete)

          to_delete
        end

        def delete_from(params, to_delete)
          to_delete.each { |x| params.delete(x) }
        end

        def add_properties_to_definition(definition, properties, required)
          definition[:properties].merge!(properties)
          definition[:required] = required
          definition.delete(:required) if definition[:required].blank?
        end

        def build_properties(params)
          properties = {}
          required = []

          prepare_nested_types(params) if should_expose_as_array?(params)

          params.each do |param|
            name = param[:name].to_sym
            properties[name] = {}

            if should_expose_as_array?([param])
              prepare_nested_types([param])

              properties[name][:type] = 'array'
              properties[name][:items] = {}
              properties[name][:items].tap do |x|
                property_keys.each do |attribute|
                  x[attribute] = param[attribute] unless param[attribute].nil?
                end
              end
            else

              properties[name].tap do |x|
                property_keys.each do |attribute|
                  x[attribute] = param[attribute] unless param[attribute].nil?
                end
              end
            end

            required << name if deletable?(param) && param[:required]
          end

          [properties, required]
        end

        def build_body_parameter(reference, name)
          {}.tap do |x|
            x[:name] = name
            x[:in] = 'body'
            x[:required] = true
            x[:schema] = { '$ref' => "#/definitions/#{reference}" }
          end
        end

        def build_definition(name, params, verb = nil)
          name = "#{verb}#{name}" if verb
          @definitions[name] = { type: should_exposed_as(params), properties: {}, required: [] }

          name
        end

        def prepare_nested_types(params)
          params.each do |param|
            next unless param[:items]
            param[:type] = param[:items][:type] == 'array' ? 'string' : param[:items][:type]
            param[:format] = param[:items][:format] if param[:items][:format]
            param.delete(:items)
          end
        end

        def prepare_nested_names(property, params)
          params.each { |x| x[:name] = x[:name].sub(property, '').sub('[', '').sub(']', '') }
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
          [:type, :format, :description, :minimum, :maximum, :items]
        end

        def deletable?(param)
          param[:in] == 'body'
        end

        def move_methods
          [:post, :put, :patch, 'POST', 'PUT', 'PATCH']
        end

        def includes_body_param?(params)
          params.map { |x| return true if x[:in] == 'body' || x[:param_type] == 'body' }
          false
        end

        def should_expose_as_array?(params)
          should_exposed_as(params) == 'array'
        end

        def should_exposed_as(params)
          params.map { |x| return 'object' if x[:type] && x[:type] != 'array' }
          'array'
        end
      end
    end
  end
end
