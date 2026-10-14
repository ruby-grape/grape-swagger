# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Builder
      # The object handed to model parsers as their "endpoint" argument.
      #
      # The shipped parsers (grape-swagger-entity, grape-swagger-representable)
      # only ever call `expose_params_from_model(model)` on it, to register a
      # nested model and get its definition name back. That is the whole contract;
      # definitions are owned by the Builder, never by the Grape endpoint.
      class ParserContext
        def initialize(&expose)
          @expose = expose
        end

        def expose_params_from_model(model)
          @expose.call(model)
        end
      end
    end
  end
end
