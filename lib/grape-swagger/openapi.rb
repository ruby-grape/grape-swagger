# frozen_string_literal: true

require_relative 'openapi/schema'
require_relative 'openapi/info'
require_relative 'openapi/server'
require_relative 'openapi/media_type'
require_relative 'openapi/parameter'
require_relative 'openapi/request_body'
require_relative 'openapi/response'
require_relative 'openapi/operation'
require_relative 'openapi/path_item'
require_relative 'openapi/security_scheme'
require_relative 'openapi/tag'
require_relative 'openapi/components'
require_relative 'openapi/document'

module GrapeSwagger
  module OpenAPI
    # Version-agnostic API model for OpenAPI/Swagger specifications.
    # This layer provides a unified representation that can be exported
    # to Swagger 2.0, OpenAPI 3.0, or OpenAPI 3.1 formats.
  end
end
