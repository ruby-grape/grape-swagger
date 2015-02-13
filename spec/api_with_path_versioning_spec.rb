require 'spec_helper'

describe 'Api with "path" versioning' do
  let(:json_body) { JSON.parse(last_response.body) }

  before :all do
    class ApiWithPathVersioning < Grape::API
      format :json
      version 'v1', using: :path

      namespace :resources do
        get
      end

      add_swagger_documentation api_version: 'v1'
    end
  end

  def app
    ApiWithPathVersioning
  end

  it 'retrieves swagger-documentation on /swagger_doc that contains :resources api path' do
    get '/v1/swagger_doc'

    expect(json_body['apis']).to eq(
      [
        { 'path' => '/resources.{format}', 'description' => 'Operations about resources' },
        { 'path' => '/swagger_doc.{format}', 'description' => 'Operations about swagger_docs' }
      ]
    )
  end
end
