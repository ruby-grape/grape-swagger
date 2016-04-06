module GrapeSwagger
  module DocMethods
    class MoveParams
      class << self
        def to_definition(paths, definitions)
          @definitions = definitions
          find_post_put(paths) do |path|
            find_definition_and_parameters(path)
          end
        end

        def find_post_put(paths)
          paths.each do |x|
            found = x.last.select { |y| move_methods.include?(y) }
            yield found unless found.empty?
          end
        end

        def find_definition_and_parameters(path)
          path.keys.each do |verb|
            parameters = path[verb][:parameters]

            next if parameters.nil?
            next unless should_move?(parameters)

            unify!(parameters)

            status_code = GrapeSwagger::DocMethods::StatusCodes.get[verb.to_sym][:code]
            response = path[verb][:responses][status_code]
            referenced_definition = parse_model(response[:schema]['$ref'])

            name = build_definition(verb, referenced_definition)

            move_params_to_new(verb, name, parameters)
            @definitions[name].delete(:required) if @definitions[name][:required].empty?
            path[verb][:parameters] << build_body_parameter(response.dup, name)
          end
        end

        def build_definition(verb, name)
          name = "#{verb}Request#{name}".to_sym
          @definitions[name] = { type: 'object', properties: {}, required: [] }

          name
        end

        def move_params_to_new(_, name, parameters)
          properties = {}
          definition = @definitions[name]
          request_parameters = parameters.dup

          request_parameters.each do |param|
            next unless movable?(param)
            name = param[:name].to_sym
            properties[name] = {}

            properties[name].tap do |x|
              property_keys.each do |attribute|
                x[attribute] = param[attribute] unless param[attribute].nil?
              end
            end

            properties[name][:readOnly] = true unless deletable?(param)
            parameters.delete(param) if deletable?(param)
            definition[:required] << name if deletable?(param) && param[:required]
          end

          definition[:properties] = properties
        end

        def build_body_parameter(response, name = false)
          body_param = {}
          body_param.tap do |x|
            x[:name] = parse_model(response[:schema]['$ref'])
            x[:in] = 'body'
            x[:required] = true
            x[:schema] = { '$ref' => response[:schema]['$ref'] } unless name
            x[:schema] = { '$ref' => "#/definitions/#{name}" } if name
          end
        end

        private

        def unify!(params)
          params.each do |param|
            param[:in] = param.delete(:param_type) if param.key?(:param_type)
            param[:in] = 'body' if param[:in] == 'formData'
          end
        end

        def parse_model(ref)
          ref.split('/').last
        end

        def move_methods
          [:post, :put, :patch]
        end

        def property_keys
          [:type, :format, :description, :minimum, :maximum, :items]
        end

        def movable?(param)
          return true if param[:in] == 'body' || param[:in] == 'path'
          false
        end

        def deletable?(param)
          return true if movable?(param) && param[:in] == 'body'
          false
        end

        def should_move?(parameters)
          !parameters.select { |x| x[:in] == 'body' || x[:param_type] == 'body' }.empty?
        end
      end
    end
  end
end
