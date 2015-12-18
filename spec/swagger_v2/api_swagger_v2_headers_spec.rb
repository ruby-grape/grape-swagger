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
    expect(subject['paths']['/use_headers']['get']).to include('headers')
    expect(subject['paths']['/use_headers']['get']['headers']).to eql({
      "X-Rate-Limit-Limit"=>{"description"=>"The number of allowed requests in the current period", "type"=>"integer"}
    })
  end
end
