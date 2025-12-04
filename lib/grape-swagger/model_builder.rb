# frozen_string_literal: true

require_relative 'model_builder/schema_builder'
require_relative 'model_builder/parameter_builder'
require_relative 'model_builder/response_builder'
require_relative 'model_builder/operation_builder'
require_relative 'model_builder/spec_builder'
require_relative 'model_builder/direct_spec_builder'

module GrapeSwagger
  module ModelBuilder
    # Model builders convert Grape routes and Swagger hashes to ApiModel objects.
    # This provides a clean abstraction layer for generating different output formats.
  end
end
