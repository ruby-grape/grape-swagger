# frozen_string_literal: true

require_relative 'api_model/schema'
require_relative 'api_model/info'
require_relative 'api_model/server'
require_relative 'api_model/media_type'
require_relative 'api_model/parameter'
require_relative 'api_model/request_body'
require_relative 'api_model/response'
require_relative 'api_model/operation'
require_relative 'api_model/path_item'
require_relative 'api_model/security_scheme'
require_relative 'api_model/tag'
require_relative 'api_model/components'
require_relative 'api_model/spec'

module GrapeSwagger
  module ApiModel
    # Version-agnostic API model for OpenAPI/Swagger specifications.
    # This layer provides a unified representation that can be exported
    # to Swagger 2.0, OpenAPI 3.0, or OpenAPI 3.1 formats.
  end
end
