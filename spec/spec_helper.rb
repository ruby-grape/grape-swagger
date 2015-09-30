$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

Dir[File.join(Dir.getwd, 'spec/support/**/*.rb')].each { |f| require f }

require 'grape'
require 'grape-swagger'
require 'grape-entity'

Bundler.setup :default, :test

require 'rack'
require 'rack/test'

RSpec.configure do |config|
  require 'rspec/expectations'
  config.include RSpec::Matchers
  config.mock_with :rspec
  config.include Rack::Test::Methods
  config.raise_errors_for_deprecations!
end
