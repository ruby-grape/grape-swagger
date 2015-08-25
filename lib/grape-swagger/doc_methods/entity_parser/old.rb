module GrapeSwagger
  module DocMethods
    module OldEntityParser
      def parse_entity_models(models)
        models.each_with_object({}) do |model, result|
          name       = (model.instance_variable_get(:@root) || parse_entity_name(model))
          properties = {}
          required   = []

          model.documentation.each do |property_name, property_info|
            p = property_info.dup

            required << property_name.to_s if p.delete(:required)

            type = if p[:type]
                     p.delete(:type)
                   else
                     exposure = model.exposures[property_name]
                     parse_entity_name(exposure[:using]) if exposure
                   end

            if p.delete(:is_array)
              p[:items] = generate_typeref(type)
              p[:type] = 'array'
            else
              p.merge! generate_typeref(type)
            end

            # rename Grape Entity's "desc" to "description"
            property_description = p.delete(:desc)
            p[:description] = property_description if property_description

            # rename Grape's 'values' to 'enum'
            select_values = p.delete(:values)
            if select_values
              select_values = select_values.call if select_values.is_a?(Proc)
              p[:enum] = select_values
            end

            if PRIMITIVE_MAPPINGS.key?(p['type'])
              p['type'], p['format'] = PRIMITIVE_MAPPINGS[p['type']]
            end

            properties[property_name] = p
          end

          result[name] = {
            id:         name,
            properties: properties
          }
          result[name].merge!(required: required) unless required.empty?
        end
      end

      def models_with_included_presenters(models)
        models + models.flat_map do |model|
          # get model references from exposures with a documentation
          nested_models = model.exposures.map do |_, config|
            if config.key?(:documentation)
              model = config[:using]
              model.respond_to?(:constantize) ? model.constantize : model
            end
          end.compact

          # get all nested models recursively
          models_with_included_presenters(nested_models)
        end
      end
    end
  end
end
