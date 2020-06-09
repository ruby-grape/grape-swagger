# frozen_string_literal: true

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
          when 'Grape::API::Boolean'
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
            type_as_string = raw_data_type.gsub(/[\[\s+\]]/, '').split(',').first
            begin
              Object.const_get(type_as_string)
            rescue NameError
              type_as_string
            end
          when Array
            raw_data_type.first
          else
            raw_data_type
          end
        end

        def parse_entity_name(model)
          if model.respond_to?(:entity_name)
            model.entity_name
          elsif model.to_s.end_with?('::Entity', '::Entities')
            model.to_s.split('::')[0..-2].join('_')
          elsif model.to_s.start_with?('Entity::', 'Entities::', 'Representable::')
            model.to_s.split('::')[1..-1].join('_')
          else
            model.to_s.split('::').join('_')
          end
        end

        def request_primitive?(type)
          request_primitives.include?(type.to_s.downcase)
        end

        def primitive?(type)
          primitives.include?(type.to_s.downcase)
        end

        def request_primitives
          primitives + %w[object string boolean file json array]
        end

        def primitives
          PRIMITIVE_MAPPINGS.keys.map(&:downcase)
        end

        def mapping(value)
          PRIMITIVE_MAPPINGS[value] || 'string'
        end

        def collections
          %w[csv ssv tsv pipes multi brackets]
        end
      end

      PRIMITIVE_MAPPINGS = {
        'integer' => %w[integer int32],
        'long' => %w[integer int64],
        'float' => %w[number float],
        'double' => %w[number double],
        'byte' => %w[string byte],
        'date' => %w[string date],
        'dateTime' => %w[string date-time],
        'binary' => %w[string binary],
        'password' => %w[string password],
        'email' => %w[string email],
        'uuid' => %w[string uuid]
      }.freeze
    end
  end
end
