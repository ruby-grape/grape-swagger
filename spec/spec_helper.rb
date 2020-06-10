# frozen_string_literal: true

if RUBY_ENGINE == 'ruby'
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter 'spec/'
    add_filter 'example/'
  end
  Coveralls.wear!
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

MODEL_PARSER = ENV.key?('MODEL_PARSER') ? ENV['MODEL_PARSER'].to_s.downcase.sub('grape-swagger-', '') : 'mock'

require 'grape'
require 'grape-swagger'

Dir[File.join(Dir.getwd, 'spec/support/*.rb')].sort.each { |f| require f }
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
  config.raise_errors_for_deprecations!

  config.order = 'random'
  config.seed = 40_834
end
