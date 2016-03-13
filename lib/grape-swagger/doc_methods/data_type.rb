module GrapeSwagger
  module DocMethods
    class DataType
      class << self
        def call(value)
          raw_data_type = value[:type] if value.is_a?(Hash)
          raw_data_type ||= 'string'
          case raw_data_type.to_s
          when 'Hash'
            'object'
          when 'Rack::Multipart::UploadedFile'
            'File'
          when 'Virtus::Attribute::Boolean'
            'boolean'
          when 'Boolean', 'Date', 'Integer', 'String', 'Float'
            raw_data_type.to_s.downcase
          when 'BigDecimal'
            'long'
          when 'DateTime'
            'dateTime'
          when 'Numeric'
            'double'
          when 'Symbol'
            'string'
          else
            parse_entity_name(raw_data_type)
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
      end

      PRIMITIVE_MAPPINGS = {
        'integer' => %w(integer int32),
        'long' => %w(integer int64),
        'float' => %w(number float),
        'double' => %w(number double),
        'byte' => %w(string byte),
        'date' => %w(string date),
        'dateTime' => %w(string date-time)
      }.freeze
    end
  end
end
