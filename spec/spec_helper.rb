# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

MODEL_PARSER = ENV.key?('MODEL_PARSER') ? ENV['MODEL_PARSER'].to_s.downcase.sub('grape-swagger-', '') : 'mock'

require 'ostruct'
require 'grape'
require 'grape-swagger'

Dir[File.join(Dir.getwd, 'spec/support/*.rb')].each { |f| require f }
require "grape-swagger/#{MODEL_PARSER}" if MODEL_PARSER != 'mock'
require File.join(Dir.getwd, "spec/support/model_parsers/#{MODEL_PARSER}_parser.rb")
require_relative 'support/model_parsers/custom_parsed_type_parser'

require 'grape-entity'
require 'grape-swagger-entity'

Bundler.setup :default, :test

require 'pry'
require 'rack'
require 'rack/test'
require 'super_diff/rspec' if ENV.key?('SUPER_DIFF')

RSpec.configure do |config|
  require 'rspec/expectations'
  config.include RSpec::Matchers
  config.mock_with :rspec
  config.include Rack::Test::Methods
  config.raise_errors_for_deprecations!

  config.order = 'random'
  config.seed = 40_834
end
