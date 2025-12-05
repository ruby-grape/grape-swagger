# frozen_string_literal: true

require_relative 'builder/schema_builder'
require_relative 'builder/parameter_builder'
require_relative 'builder/response_builder'
require_relative 'builder/operation_builder'
require_relative 'builder/from_hash'
require_relative 'builder/from_routes'

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builders convert Grape routes and Swagger hashes to OpenAPI model objects.
      # This provides a clean abstraction layer for generating different output formats.
    end
  end
end
