module GrapeSwagger
  module DocMethods
    class MoveParams
      class << self
        attr_accessor :definitions

        def to_definition(params, route, definitions)
          @definitions = definitions

          parent_definition_of_params(params, route)
        end

        def can_be_moved?(params, http_verb)
          move_methods.include?(http_verb) && includes_body_param?(params)
        end

        def parent_definition_of_params(params, route)
          unify!(params)

          definition_name = GrapeSwagger::DocMethods::OperationId.manipulate(parse_model(route.path))
          referenced_definition = build_definition(definition_name, route.request_method.downcase)
          definition = @definitions[referenced_definition]

          move_params_to_new(referenced_definition, definition, params)

          definition[:description] = route.description if route.respond_to?(:description)

          params << build_body_parameter(referenced_definition, definition_name)

          params
        end

        def move_params_to_new(definition_name, definition, params)
          properties = {}

          nested_definitions(definition_name, params, properties)

          params.dup.each do |param|
            next unless movable?(param)

            name = param[:name].to_sym
            properties[name] = {}

            properties[name].tap do |x|
              property_keys.each do |attribute|
                x[attribute] = param[attribute] unless param[attribute].nil?
              end
            end

            params.delete(param) if deletable?(param)
            definition[:required] << name if deletable?(param) && param[:required]
          end

          definition.delete(:required) if definition[:required].empty?
          definition[:properties] = properties
        end

        def nested_definitions(name, params, properties)
          loop do
            nested_name = params.bsearch { |x| x[:name].include?('[') }
            return if nested_name.nil?

            nested_name = nested_name[:name].split('[').first

            nested, = params.partition { |x| x[:name].start_with?("#{nested_name}[") }
            nested.each { |x| params.delete(x) }
            nested_def_name = GrapeSwagger::DocMethods::OperationId.manipulate(nested_name)
            def_name = "#{name}#{nested_def_name}"

            if nested.first[:type] && nested.first[:type] == 'array'
              prepare_nested_types(nested)
              properties[nested_name] = { type: 'array', items: { '$ref' => "#/definitions/#{def_name}" } }
            else
              properties[nested_name] = { '$ref' => "#/definitions/#{def_name}" }
            end

            prepare_nested_names(nested)
            definition = build_definition(def_name)
            @definitions[definition][:description] = "#{name} - #{nested_name}"
            move_params_to_new(definition, @definitions[definition], nested)
          end
        end

        private

        def build_body_parameter(reference, name)
          body_param = {}
          body_param.tap do |x|
            x[:name] = name
            x[:in] = 'body'
            x[:required] = true
            x[:schema] = { '$ref' => "#/definitions/#{reference}" }
          end
        end

        def build_definition(name, verb = nil)
          name = "#{verb}#{name}" if verb
          @definitions[name] = { type: 'object', properties: {}, required: [] }

          name
        end

        def prepare_nested_types(params)
          params.each do |param|
            next unless param[:items]
            param[:type] = param[:items][:type]
            param[:format] = param[:items][:format] if param[:items][:format]
            param.delete(:items)
          end
        end

        def prepare_nested_names(params)
          params.each do |param|
            name = param[:name].partition('[').last.sub(']', '')
            name = name.partition('[').last.sub(']', '') if name.start_with?('[')
            param[:name] = name
          end
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

        def movable?(param)
          param[:in] == 'body'
        end

        alias deletable? movable?

        def move_methods
          [:post, :put, :patch, 'POST', 'PUT', 'PATCH']
        end

        def includes_body_param?(params)
          params.map { |x| return true if x[:in] == 'body' || x[:param_type] == 'body' }
          false
        end
      end
    end
  end
end
