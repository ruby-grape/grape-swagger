module GrapeSwagger
  module DocMethods
    class RequiredAttributes
      class << self
        def build(model)
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
