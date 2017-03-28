# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    class BuildModelDefinition
      class << self
        def build(model, properties)
          definition = { type: 'object', properties: properties }

          required = required_attributes(model)
          definition[:required] = required unless required.blank?

          definition
        end

        private

        def required_attributes(model)
          parse_entity(model) || parse_representable(model)
        end

        def parse_entity(model)
          return unless model.respond_to?(:documentation)

          model.documentation
               .select { |_name, options| options[:required] }
               .map { |name, options| options[:as] || name }
        end

        def parse_representable(model)
          return unless model.respond_to?(:map)

          model.map
               .select { |p| p[:documentation] && p[:documentation][:required] }
               .map(&:name)
        end
      end
    end
  end
end
