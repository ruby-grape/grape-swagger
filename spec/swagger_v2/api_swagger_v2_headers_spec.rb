require 'spec_helper'

describe 'headers' do
  include_context "the api entities"

  before :all do
    module TheApi
      class HeadersApi < Grape::API
        format :json

        desc 'This returns something',
          failure: [{code: 400, model: Entities::ApiError}],
          headers:  {
            "X-Rate-Limit-Limit" => {
              "description" => "The number of allowed requests in the current period",
              "type" => "integer"
          }},

          entity: Entities::UseResponse
        get '/use_headers' do
          { "declared_params" => declared(params) }
        end

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::HeadersApi
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  specify do
    expect(subject['paths']['/use_headers']['get']['parameters'][0]['in']).to eq('header')
    expect(subject['paths']['/use_headers']['get']['parameters'][0]).to eql({"description"=>"The number of allowed requests in the current period", "type"=>"integer", "in"=>"header", "name"=>"X-Rate-Limit-Limit"})
  end
end
