$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'support'))

require 'grape'
require 'grape-swagger'
require 'grape-entity'

require 'rubygems'
require 'bundler'

require 'json'

Bundler.setup :default, :test

require 'rack/test'

require 'i18n_helper'

RSpec.configure do |config|
  require 'rspec/expectations'
  config.include RSpec::Matchers
  config.mock_with :rspec
  config.include Rack::Test::Methods
  config.raise_errors_for_deprecations!
  config.include I18nHelper
end
