# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

MODEL_PARSER = ENV.key?('MODEL_PARSER') ? ENV['MODEL_PARSER'].to_s.downcase.sub('grape-swagger-', '') : 'mock'

require 'ostruct'
require 'grape'
require 'grape-swagger'

Dir[File.join(Dir.getwd, 'spec/support/*.rb')].each { |f| require f }
require "grape-swagger/#{MODEL_PARSER}" if MODEL_PARSER != 'mock'
require File.join(Dir.getwd, "spec/support/model_parsers/#{MODEL_PARSER}_parser.rb")

require 'grape-entity'
require 'grape-swagger-entity'

Bundler.setup :default, :test

require 'rack'
require 'rack/test'

RSpec.configure do |config|
  require 'rspec/expectations'
  config.include RSpec::Matchers
  config.mock_with :rspec
  config.include Rack::Test::Methods
  config.include ApiClassDefinitionCleaner
  config.raise_errors_for_deprecations!

  config.define_derived_metadata(file_path: /spec\/openapi_3/) do |metadata|
    metadata[:type] ||= :openapi3
  end
  config.define_derived_metadata(file_path: /spec\/swagger_v2/) do |metadata|
    metadata[:type] ||= :swagger2
  end

  config.include OpenAPI3ResponseValidationHelper, type: :openapi3

  config.order = 'random'
  config.seed = 40_834
end
