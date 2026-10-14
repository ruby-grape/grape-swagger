# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds OpenAPI::Schema objects from type definitions.
      class SchemaBuilder
        PRIMITIVE_MAPPINGS = {
          'integer' => { type: 'integer', format: 'int32' },
          'long' => { type: 'integer', format: 'int64' },
          'float' => { type: 'number', format: 'float' },
          'double' => { type: 'number', format: 'double' },
          'string' => { type: 'string' },
          'byte' => { type: 'string', format: 'byte' },
          'binary' => { type: 'string', format: 'binary' },
          'boolean' => { type: 'boolean' },
          'date' => { type: 'string', format: 'date' },
          'dateTime' => { type: 'string', format: 'date-time' },
          'password' => { type: 'string', format: 'password' },
          'email' => { type: 'string', format: 'email' },
          'uuid' => { type: 'string', format: 'uuid' },
          # JSON type maps to object
          'json' => { type: 'object' },
          # OAS 3.1 supports null as a type
          'null' => { type: 'null' }
        }.freeze

        RUBY_TYPE_MAPPINGS = {
          'Integer' => 'integer',
          'Float' => 'float',
          'BigDecimal' => 'double',
          'Numeric' => 'double',
          'TrueClass' => 'boolean',
          'FalseClass' => 'boolean',
          'String' => 'string',
          'Symbol' => 'string',
          'Date' => 'date',
          'DateTime' => 'dateTime',
          'Time' => 'dateTime',
          'Hash' => 'object',
          'Array' => 'array',
          'Rack::Multipart::UploadedFile' => 'file',
          'File' => 'file',
          # OAS 3.1 supports null as a type
          'NilClass' => 'null'
        }.freeze

        def initialize(definitions = {})
          @definitions = definitions
        end

        # Build a schema from a parameter hash (Swagger 2.0 style)
        def build_from_param(param)
          param = param.with_indifferent_access
          schema = OpenAPI::Schema.new
          ref = param_ref(param)
          if ref
            schema.canonical_name = ref.split('/').last
          elsif param[:type]
            apply_type_from_param(schema, param)
          end
          apply_param_constraints(schema, param)
          schema
        end

        # A property can point at another model directly or through a one element allOf
        # (the form used when the reference carries a description).
        def param_ref(param)
          return param['$ref'] if param['$ref']

          all_of = param[:allOf]
          all_of.first['$ref'] if all_of.is_a?(Array) && all_of.size == 1 && all_of.first.is_a?(Hash)
        end

        def apply_type_from_param(schema, param)
          type_string = normalize_type(param[:type])
          apply_typed_schema(schema, type_string, param)
        end

        def apply_typed_schema(schema, type_string, param)
          if primitive?(type_string)
            apply_primitive_from_param(schema, type_string, param)
          elsif type_string == 'array'
            apply_array_from_param(schema, param)
          elsif type_string == 'object'
            apply_object_from_param(schema, param)
          elsif type_string == 'file'
            schema.type = 'string'
            schema.format = 'binary'
          elsif @definitions.key?(type_string)
            schema.canonical_name = type_string
          else
            schema.type = type_string
          end
        end

        def apply_object_from_param(schema, param)
          schema.type = 'object'
          schema.additional_properties = param[:additionalProperties] if param.key?(:additionalProperties)
          apply_object_properties(schema, param)
          apply_object_required(schema, param)
        end

        def apply_object_properties(schema, param)
          return unless param[:properties]

          param[:properties].each do |name, prop|
            schema.add_property(name.to_s, build_from_param(prop))
          end
        end

        def apply_object_required(schema, param)
          return unless param[:required].is_a?(Array)

          param[:required].each { |name| schema.mark_required(name.to_s) }
        end

        def apply_primitive_from_param(schema, type_string, param)
          mapping = PRIMITIVE_MAPPINGS[type_string] || { type: type_string }
          schema.type = mapping[:type]
          schema.format = param[:format] || mapping[:format]
        end

        def apply_array_from_param(schema, param)
          schema.type = 'array'
          schema.items = param[:items] ? build_from_param(param[:items]) : OpenAPI::Schema.new(type: 'string')
        end

        def apply_param_constraints(schema, param)
          schema.enum = param[:enum] if param[:enum]
          schema.default = param[:default] if param.key?(:default)
          schema.minimum = param[:minimum] if param[:minimum]
          schema.maximum = param[:maximum] if param[:maximum]
          schema.min_length = param[:minLength] if param[:minLength]
          schema.max_length = param[:maxLength] if param[:maxLength]
          schema.min_items = param[:minItems] if param[:minItems]
          schema.max_items = param[:maxItems] if param[:maxItems]
          schema.pattern = param[:pattern] if param[:pattern]
          schema.description = param[:description] if param[:description]
          schema.example = param[:example] if param.key?(:example)
          schema.nullable = true if param[:nullable] || param['x-nullable']
        end

        # Build schema from a model definition hash
        def build_from_definition(definition)
          return build_ref_schema(definition) if definition_is_ref?(definition)

          schema = OpenAPI::Schema.new
          schema.type = definition[:type] if definition[:type]
          schema.description = definition[:description] if definition[:description]

          build_definition_properties(schema, definition)
          build_definition_items(schema, definition)
          build_definition_composition(schema, definition)

          schema.discriminator = definition[:discriminator] if definition[:discriminator]
          schema.additional_properties = definition[:additionalProperties] if definition.key?(:additionalProperties)

          schema
        end

        def definition_is_ref?(definition)
          definition['$ref'] || definition[:$ref]
        end

        def build_ref_schema(definition)
          ref = definition['$ref'] || definition[:$ref]
          model_name = ref.split('/').last
          schema = OpenAPI::Schema.new
          schema.canonical_name = model_name
          schema
        end

        def build_definition_properties(schema, definition)
          definition[:properties]&.each do |name, prop|
            schema.add_property(name, build_from_param(prop))
          end
          definition[:required].each { |name| schema.mark_required(name) } if definition[:required].is_a?(Array)
        end

        def build_definition_items(schema, definition)
          schema.items = build_from_definition(definition[:items]) if definition[:items]
        end

        def build_definition_composition(schema, definition)
          schema.all_of = definition[:allOf].map { |d| build_from_definition(d) } if definition[:allOf]
          schema.one_of = definition[:oneOf].map { |d| build_from_definition(d) } if definition[:oneOf]
          schema.any_of = definition[:anyOf].map { |d| build_from_definition(d) } if definition[:anyOf]
        end

        private

        def normalize_type(type)
          return type if type.is_a?(String)
          return type.name if type.is_a?(Class)
          return RUBY_TYPE_MAPPINGS[type.to_s] if RUBY_TYPE_MAPPINGS.key?(type.to_s)

          type.to_s
        end

        def primitive?(type)
          PRIMITIVE_MAPPINGS.key?(type) || %w[string integer number boolean].include?(type)
        end
      end
    end
  end
end
