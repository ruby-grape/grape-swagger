# frozen_string_literal: true

require 'grape'

require 'grape-swagger/instance'

require 'grape-swagger/version'
require 'grape-swagger/endpoint'
require 'grape-swagger/errors'

require 'grape-swagger/doc_methods'
require 'grape-swagger/model_parsers'
require 'grape-swagger/request_param_parser_registry'
require 'grape-swagger/swagger_routing'
require 'grape-swagger/swagger_documentation_adder'
require 'grape-swagger/token_owner_resolver'

# OpenAPI 3.x support
require 'grape-swagger/openapi'
require 'grape-swagger/openapi/builder'
require 'grape-swagger/exporter'

module GrapeSwagger
  class << self
    attr_writer :schema_name_generator

    def model_parsers
      @model_parsers ||= GrapeSwagger::ModelParsers.new
    end

    def request_param_parsers
      @request_param_parsers ||= GrapeSwagger::RequestParamParserRegistry.new
    end

    def schema_name_generator
      @schema_name_generator ||= default_schema_name_generator
    end

    private

    def default_schema_name_generator
      lambda { |model|
        model_string = model.to_s
        if model_string.end_with?('::Entity', '::Entities')
          model_string.split('::')[0..-2].join('_')
        elsif model_string.start_with?('Entity::', 'Entities::', 'Representable::')
          model_string.split('::')[1..-1].join('_')
        else
          model_string.split('::').join('_')
        end
      }
    end
  end
  autoload :Rake, 'grape-swagger/rake/oapi_tasks'

  # Copied from https://github.com/ruby-grape/grape/blob/v2.2.0/lib/grape/formatter.rb
  FORMATTER_DEFAULTS = {
    xml: Grape::Formatter::Xml,
    serializable_hash: Grape::Formatter::SerializableHash,
    json: Grape::Formatter::Json,
    jsonapi: Grape::Formatter::Json,
    txt: Grape::Formatter::Txt
  }.freeze

  # Copied from https://github.com/ruby-grape/grape/blob/v2.2.0/lib/grape/content_types.rb
  CONTENT_TYPE_DEFAULTS = {
    xml: 'application/xml',
    serializable_hash: 'application/json',
    json: 'application/json',
    binary: 'application/octet-stream',
    txt: 'text/plain'
  }.freeze
end

# Temporary compatibility aliases for downstream code that still references
# the pre-namespace constants directly.
SwaggerRouting = GrapeSwagger::SwaggerRouting
SwaggerDocumentationAdder = GrapeSwagger::SwaggerDocumentationAdder
Object.send(:deprecate_constant, :SwaggerRouting, :SwaggerDocumentationAdder)

GrapeInstance.extend(GrapeSwagger::SwaggerDocumentationAdder)
