module GrapeSwagger
  module DocMethods
    module EntityParser
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

    include EntityParser

    begin
      require 'grape-entity'
    rescue LoadError
      nil
    end

    if defined?(Grape::Entity)
      if GrapeEntity::VERSION < '0.5.0'
        require 'grape-swagger/doc_methods/entity_parser/old'
        include OldEntityParser
      end
    end
  end
end
