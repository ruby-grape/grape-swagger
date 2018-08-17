# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    class BuildModelDefinition
      class << self
        def build(model, properties, required)
          definition = { type: 'object', properties: properties }

          definition[:required] = required unless required.blank?

          definition
        end
      end
    end
  end
end
