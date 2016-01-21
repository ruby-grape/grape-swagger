require 'rack/cors'
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
  end
end

# run Api.new

require 'grape'
require '../lib/grape-swagger'

require './api'

class Base < Grape::API
  format :json

  mount Api::Root
  mount Api::Splines
  mount Api::FileAccessor

  before do
    header['Access-Control-Allow-Origin'] = '*'
    header['Access-Control-Request-Method'] = '*'
  end

  # global exception handler, used for error notifications
  rescue_from :all do |e|
    raise e
    error_response(message: "Internal server error: #{e}", status: 500)
  end

  add_swagger_documentation :format => :json,
                            :hide_documentation_path => true,
                            :api_version => 'v1',
                            :info => {
                              title: "Horses and Hussars",
                              description: "Demo app for dev of grape swagger 2.0"
                            }

end


run Base.new
