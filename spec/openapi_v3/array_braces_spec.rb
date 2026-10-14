# frozen_string_literal: true

require 'spec_helper'

describe 'OAS 3.0 array_use_braces' do
  let(:app) do
    Class.new(Grape::API) do
      format :json

      params { optional :ids, type: Array[Integer] }
      get('/query') { {} }

      params do
        optional :ids, type: Array[Integer]
        optional :name, type: String
      end
      post('/json') { {} }

      desc 'form', consumes: ['application/x-www-form-urlencoded']
      params do
        optional :ids, type: Array[Integer]
        optional :name, type: String
      end
      post('/form') { {} }

      add_swagger_documentation openapi_version: '3.0', array_use_braces: true
    end
  end

  let(:paths) do
    get '/swagger_doc'
    JSON.parse(last_response.body)['paths']
  end

  it 'emits a single braced query parameter, as Swagger 2.0 does' do
    expect(paths['/query']['get']['parameters'].map { |p| p['name'] }).to eq(['ids[]'])
  end

  it 'keeps braced property names in form-encoded request bodies' do
    props = paths['/form']['post']['requestBody']['content']['application/x-www-form-urlencoded']['schema']['properties']
    expect(props.keys).to contain_exactly('ids[]', 'name')
    expect(props['ids[]']['type']).to eq('array')
  end

  it 'uses the bare name in JSON request bodies' do
    get '/swagger_doc'
    schemas = JSON.parse(last_response.body)['components']['schemas']
    expect(schemas['postJson']['properties'].keys).to contain_exactly('ids', 'name')
  end
end
