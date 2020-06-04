# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    class BuildModelDefinition
      class << self
        def build(model, properties, required, other_def_properties = {})
          definition = { type: 'object', properties: properties }.merge(other_def_properties)

          if required.nil?
            required_attrs = required_attributes(model)
            definition[:required] = required_attrs unless required_attrs.blank?
          end

          definition[:required] = required if required.is_a?(Array) && required.any?

          definition
        end

        private

        def required_attributes(model)
          parse_entity(model) || parse_representable(model)
        end

        def parse_entity(model)
          return unless model.respond_to?(:documentation)
        end

        def parse_representable(model)
          return unless model.respond_to?(:map)
        end
      end
    end
  end
end
