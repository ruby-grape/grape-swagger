# frozen_string_literal: true

module GrapeSwagger
  module Errors
    class UnregisteredParser < StandardError; end

    class SwaggerSpec < StandardError; end

    class SwaggerSpecDeprecated < SwaggerSpec
      class << self
        def tell!(what)
          warn "[GrapeSwagger] usage of #{what} is deprecated"
        end
      end
    end
  end
end
