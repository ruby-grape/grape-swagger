Bundler.require ENV['RACK_ENV']

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
  end
end

require 'grape'

require './api/endpoints'
require './api/entities'

class Base < Grape::API
  require '../lib/grape-swagger'
  format :json

  mount Api::Endpoints::Root
  mount Api::Endpoints::Splines
  mount Api::Endpoints::FileAccessor

  before do
    header['Access-Control-Allow-Origin'] = '*'
    header['Access-Control-Request-Method'] = '*'
  end

  # global exception handler, used for error notifications
  rescue_from :all do |e|
    raise e
    error_response(message: "Internal server error: #{e}", status: 500)
  end

  add_swagger_documentation hide_documentation_path: true,
                            api_version: 'v1',
                            info: {
                              title: 'Horses and Hussars',
                              description: 'Demo app for dev of grape swagger 2.0'
                            }
end

run Base.new
