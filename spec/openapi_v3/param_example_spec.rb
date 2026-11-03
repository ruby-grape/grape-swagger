# frozen_string_literal: true

require 'spec_helper'

describe 'Parameter examples in OAS 3.x output' do
  before :all do
    module ParamExampleOAS3
      class API < Grape::API
        format :json

        desc 'Search'
        params do
          optional :term, type: String, documentation: { example: 'grape' }
        end
        get('/search') { {} }

        desc 'Create'
        params do
          optional :name, type: String, documentation: { example: 'Ada' }
          optional :active, type: Grape::API::Boolean, documentation: { example: false }
          optional :count, type: Integer, documentation: { example: 0 }
        end
        post('/people') { {} }

        add_swagger_documentation(openapi_version: '3.0')
      end

      class API31 < Grape::API
        format :json

        desc 'Search'
        params do
          optional :term, type: String, documentation: { example: 'grape' }
        end
        get('/search') { {} }

        add_swagger_documentation(openapi_version: '3.1')
      end
    end
  end

  def app
    ParamExampleOAS3::API
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  it 'keeps the example of a query parameter' do
    param = subject['paths']['/search']['get']['parameters'].first

    expect(param['schema']['example']).to eq('grape')
  end

  it 'keeps the example of a body property' do
    props = subject['components']['schemas']['postPeople']['properties']

    expect(props['name']['example']).to eq('Ada')
  end

  it 'keeps falsy examples such as false and 0' do
    props = subject['components']['schemas']['postPeople']['properties']

    expect(props['active']['example']).to be false
    expect(props['count']['example']).to eq 0
  end

  it 'keeps the example of a query parameter in 3.1' do
    response = Rack::MockRequest.new(ParamExampleOAS3::API31).get('/swagger_doc')
    param = JSON.parse(response.body)['paths']['/search']['get']['parameters'].first

    expect(param['schema']['example']).to eq('grape')
  end
end
