# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    class BuildModelDefinition
      class << self
        OBJECT_ATTRIBUTE_KEYS = %i[
          $ref type
        ].freeze

        def build(_model, properties, required, other_def_properties = {})
          definition = { type: 'object', properties: properties }.merge(other_def_properties)

          definition[:required] = required if required.is_a?(Array) && required.any?

          definition
        end

        def parse_params_from_model(parsed_response, model, model_name)
          # If the parsed response looks like a complete object (e.g., containing `$ref` or `type`),
          # it uses the provided response as-is.
          return parsed_response if complete_object?(parsed_response)

          if parsed_response.is_a?(Hash) && parsed_response.keys.first == :allOf
            refs_or_models = parsed_response[:allOf]
            parsed = parse_refs_and_models(refs_or_models, model)

            {
              allOf: parsed
            }
          else
            properties, required = parsed_response
            unless properties&.any?
              raise GrapeSwagger::Errors::SwaggerSpec,
                    "Empty model #{model_name}, swagger 2.0 doesn't support empty definitions."
            end
            properties, other_def_properties = parse_properties(properties)

            build(
              model, properties, required, other_def_properties
            )
          end
        end

        def parse_properties(properties)
          other_properties = {}

          discriminator_key, discriminator_value =
            properties.find do |_key, value|
              value[:documentation].try(:[], :is_discriminator)
            end

          if discriminator_key
            discriminator_value.delete(:documentation)
            properties[discriminator_key] = discriminator_value

            other_properties[:discriminator] = discriminator_key
          end

          [properties, other_properties]
        end

        def parse_refs_and_models(refs_or_models, model)
          refs_or_models.map do |ref_or_models|
            if complete_object?(ref_or_models)
              ref_or_models
            else
              properties, required = ref_or_models
              GrapeSwagger::DocMethods::BuildModelDefinition.build(model, properties, required)
            end
          end
        end

        private

        # Checks if the parsed response is already a complete object.
        #
        # @param parsed_response [Hash] The parsed response to check.
        # @return [Boolean] True if the response has object attributes.
        def complete_object?(parsed_response)
          return false unless parsed_response.is_a?(Hash)

          parsed_response.keys.intersect?(OBJECT_ATTRIBUTE_KEYS)
        end
      end
    end
  end
end
