$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

Dir[File.join(Dir.getwd, 'spec/support/*.rb')].each { |f| require f }
MODEL_PARSER = ENV.key?('MODEL_PARSER') ? ENV['MODEL_PARSER'].to_s.downcase.sub('grape-swagger-', '') : 'mock'

require 'grape'
require 'grape-swagger'
require "grape-swagger/#{MODEL_PARSER}" if MODEL_PARSER != 'mock'
require File.join(Dir.getwd, "spec/support/model_parsers/#{MODEL_PARSER}_parser.rb")

Bundler.setup :default, :test

require 'rack'
require 'rack/test'

RSpec.configure do |config|
  require 'rspec/expectations'
  config.include RSpec::Matchers
  config.mock_with :rspec
  config.include Rack::Test::Methods
  config.raise_errors_for_deprecations!

  config.order = 'random'
  config.seed = 40_834
end
