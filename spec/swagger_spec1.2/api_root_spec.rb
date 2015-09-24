require 'spec_helper'

describe 'simple root api' do
  before :all do
    class ApiRoot < Grape::API
      format :json
      prefix 'api'
      version 'v2', using: :header, vendor: 'artsy', strict: false
      get do
        {}
      end
      add_swagger_documentation
    end
  end

  def app
    ApiRoot
  end

  it 'retrieves swagger-documentation on /swagger_doc' do
    get '/api/swagger_doc'
    expect(JSON.parse(last_response.body)).to eq({
      'swagger' => '2.0',
      'info' => {
        'title' => 'API title',
        'version' => '0.1'
      },
      'produces' => ['application/json'],
      'paths' => [{'path' => '/swagger_doc.{format}', 'description' => 'Operations about swagger_docs'}
      ]}
    )
  end
end
