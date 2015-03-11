require 'spec_helper'

describe 'API with Prefix and Namespace' do
  def app
    Class.new(Grape::API) do
      format :json
      prefix 'api'

      namespace :status do
        desc 'Retrieve status.'
        get do
        end
      end

      add_swagger_documentation
    end
  end

  subject do
    get '/api/swagger_doc'
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    body['apis']
  end

  it 'gets array types' do
    expect(subject).to eq([
      { 'path' => '/status.{format}', 'description' => 'Operations about statuses' },
      { 'path' => '/swagger_doc.{format}', 'description' => 'Operations about swagger_docs' }
    ])
  end
end
