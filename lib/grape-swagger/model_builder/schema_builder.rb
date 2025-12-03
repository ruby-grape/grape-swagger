# frozen_string_literal: true

module GrapeSwagger
  module ModelBuilder
    # Builds ApiModel::Schema objects from type definitions.
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
        'Fixnum' => 'integer',
        'Bignum' => 'integer',
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
        'JSON' => 'object',
        'Array' => 'array',
        'Rack::Multipart::UploadedFile' => 'file',
        'File' => 'file',
        # OAS 3.1 supports null as a type
        'NilClass' => 'null'
      }.freeze

      def initialize(definitions = {})
        @definitions = definitions
      end

      # Build a schema from a data type string or class
      def build(type, options = {})
        schema = ApiModel::Schema.new

        type_string = normalize_type(type)

        if primitive?(type_string)
          apply_primitive(schema, type_string, options)
        elsif type_string == 'array'
          build_array_schema(schema, options)
        elsif type_string == 'object'
          build_object_schema(schema, options)
        elsif type_string == 'file'
          schema.type = 'string'
          schema.format = 'binary'
        elsif @definitions.key?(type_string)
          # Reference to a defined model
          schema.canonical_name = type_string
        else
          # Default to string for unknown types
          schema.type = 'string'
        end

        apply_common_options(schema, options)
        schema
      end

      # Build a schema from a parameter hash (Swagger 2.0 style)
      def build_from_param(param)
        schema = ApiModel::Schema.new

        if param[:type]
          type_string = normalize_type(param[:type])

          if primitive?(type_string)
            mapping = PRIMITIVE_MAPPINGS[type_string] || { type: type_string }
            schema.type = mapping[:type]
            schema.format = param[:format] || mapping[:format]
          elsif type_string == 'array'
            schema.type = 'array'
            schema.items = if param[:items]
                             build_from_param(param[:items])
                           else
                             ApiModel::Schema.new(type: 'string')
                           end
          elsif type_string == 'object'
            schema.type = 'object'
          elsif type_string == 'file'
            schema.type = 'string'
            schema.format = 'binary'
          elsif @definitions.key?(type_string)
            schema.canonical_name = type_string
          else
            schema.type = type_string
          end
        end

        # Apply constraints
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

        schema
      end

      # Build schema from a model definition hash
      def build_from_definition(definition)
        schema = ApiModel::Schema.new

        # Handle $ref - extract model name from reference
        if definition['$ref'] || definition[:$ref]
          ref = definition['$ref'] || definition[:$ref]
          # Extract model name from "#/definitions/ModelName" or "#/components/schemas/ModelName"
          model_name = ref.split('/').last
          schema.canonical_name = model_name
          return schema
        end

        schema.type = definition[:type] if definition[:type]
        schema.description = definition[:description] if definition[:description]

        definition[:properties]&.each do |name, prop|
          schema.add_property(name, build_from_param(prop))
        end

        definition[:required].each { |name| schema.mark_required(name) } if definition[:required].is_a?(Array)

        schema.items = build_from_definition(definition[:items]) if definition[:items]

        schema.all_of = definition[:allOf].map { |d| build_from_definition(d) } if definition[:allOf]

        schema.additional_properties = definition[:additionalProperties] if definition.key?(:additionalProperties)

        schema
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

      def apply_primitive(schema, type, options)
        mapping = PRIMITIVE_MAPPINGS[type] || { type: type }
        schema.type = mapping[:type]
        schema.format = options[:format] || mapping[:format]
      end

      def build_array_schema(schema, options)
        schema.type = 'array'
        schema.items = if options[:items]
                         build(options[:items][:type] || 'string', options[:items])
                       else
                         ApiModel::Schema.new(type: 'string')
                       end
      end

      def build_object_schema(schema, options)
        schema.type = 'object'
        return unless options[:properties]

        options[:properties].each do |name, prop_options|
          schema.add_property(name, build(prop_options[:type] || 'string', prop_options))
        end
      end

      def apply_common_options(schema, options)
        schema.description = options[:description] if options[:description]
        schema.enum = options[:enum] if options[:enum]
        schema.default = options[:default] if options.key?(:default)
        schema.nullable = options[:nullable] if options.key?(:nullable)
        schema.example = options[:example] if options.key?(:example)
        schema.minimum = options[:minimum] if options[:minimum]
        schema.maximum = options[:maximum] if options[:maximum]
        schema.min_length = options[:min_length] if options[:min_length]
        schema.max_length = options[:max_length] if options[:max_length]
      end
    end
  end
end
