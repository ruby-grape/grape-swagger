# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    class FormatData
      class << self
        def to_format(parameters)
          parameters.reject { |parameter| parameter[:in] == 'body' }.each do |b|
            related_parameters = parameters.select do |p|
              p[:name] != b[:name] && p[:name].start_with?("#{b[:name].to_s.gsub(/\[\]\z/, '')}[")
            end
            parameters.reject! { |p| p[:name] == b[:name] } if move_down(b, related_parameters)
          end
          parameters
        end

        def move_down(parameter, related_parameters)
          case parameter[:type]
          when 'array'
            add_array(parameter, related_parameters)
            unless related_parameters.blank?
              add_braces(parameter, related_parameters) if parameter[:name].match?(/\A.*\[\]\z/)
              return true
            end
          when 'object'
            return true
          end
          false
        end

        def add_braces(parameter, related_parameters)
          param_name = parameter[:name].gsub(/\A(.*)\[\]\z/, '\1')
          related_parameters.each { |p| p[:name] = p[:name].gsub(param_name, "#{param_name}[]") }
        end

        def add_array(parameter, related_parameters)
          related_parameters.each do |p|
            next if p.key?(:items)

            p_type = p[:type] == 'array' ? 'string' : p[:type]
            p[:items] = { type: p_type, format: p[:format], enum: p[:enum], is_array: p[:is_array] }
            p[:items].compact!
            p[:type] = 'array'
            p[:is_array] = parameter[:is_array]
            p.delete(:format)
            p.delete(:enum)
            p.compact!
          end
        end
      end
    end
  end
end
