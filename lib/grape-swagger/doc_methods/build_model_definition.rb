# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    class BuildModelDefinition
      class << self
        def build(model, properties, required)
          definition = { type: 'object', properties: properties }

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

          deprecated_workflow_for('grape-swagger-entity')

          model.documentation
               .select { |_name, options| options[:required] }
               .map { |name, options| options[:as] || name }
        end

        def parse_representable(model)
          return unless model.respond_to?(:map)

          deprecated_workflow_for('grape-swagger-representable')

          model.map
               .select { |p| p[:documentation] && p[:documentation][:required] }
               .map(&:name)
        end

        def deprecated_workflow_for(gem_name)
          warn "DEPRECATED: You are using old #{gem_name} version, which doesn't provide " \
            "required attributes. To solve this problem, please update #{gem_name}"
        end
      end
    end
  end
end
