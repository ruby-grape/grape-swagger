module GrapeSwagger
  module DocMethods
    class DataType
      class << self
        def call(value)
          raw_data_type = value.is_a?(Hash) ? value[:type] : value
          raw_data_type ||= 'String'
          raw_data_type = parse_multi_type(raw_data_type)

          case raw_data_type.to_s
          when 'Boolean', 'Date', 'Integer', 'String', 'Float', 'JSON', 'Array'
            raw_data_type.to_s.downcase
          when 'Hash'
            'object'
          when 'Rack::Multipart::UploadedFile', 'File'
            'file'
          when 'Virtus::Attribute::Boolean'
            'boolean'
          when 'BigDecimal'
            'double'
          when 'DateTime', 'Time'
            'dateTime'
          when 'Numeric'
            'long'
          when 'Symbol'
            'string'
          else
            parse_entity_name(raw_data_type)
          end
        end

        def parse_multi_type(raw_data_type)
          case raw_data_type
          when /\A\[.*\]\z/
            raw_data_type.gsub(/[(\A\[)(\s+)(\]\z)]/, '').split(',').first
          when Array
            raw_data_type.first
          else
            raw_data_type
          end
        end

        def parse_entity_name(model)
          if model.respond_to?(:entity_name)
            model.entity_name
          else
            name = model.to_s
            entity_parts = name.split('::')
            entity_parts.reject! { |p| p == 'Entity' || p == 'Entities' }
            entity_parts.join('::')
          end
        end

        def request_primitive?(type)
          request_primitives.include?(type.to_s.downcase)
        end

        def primitive?(type)
          primitives.include?(type.to_s.downcase)
        end

        def request_primitives
          primitives + %w(object string boolean file json array)
        end

        def primitives
          PRIMITIVE_MAPPINGS.keys.map(&:downcase)
        end

        def mapping(value)
          PRIMITIVE_MAPPINGS[value] || 'string'
        end
      end

      PRIMITIVE_MAPPINGS = {
        'integer' => %w(integer int32),
        'long' => %w(integer int64),
        'float' => %w(number float),
        'double' => %w(number double),
        'byte' => %w(string byte),
        'date' => %w(string date),
        'dateTime' => %w(string date-time),
        'binary' => %w(string binary),
        'password' => %w(string password),
        'email' => %w(string email)
      }.freeze
    end
  end
end
