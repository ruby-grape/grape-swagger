# frozen_string_literal: true

require 'spec_helper'

describe 'response with models for OAS 3.0' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApiOAS3
      class ResponseApiModels < Grape::API
        format :json

        desc 'This returns something',
             success: [{ code: 200 }],
             failure: [
               { code: 400, message: 'NotFound', model: '' },
               { code: 404, message: 'BadRequest', model: Entities::ApiError }
             ],
             default_response: { message: 'Error', model: Entities::ApiError }
        get '/use-response' do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation(
          openapi_version: '3.0',
          models: [Entities::UseResponse]
        )
      end
    end
  end

  def app
    TheApiOAS3::ResponseApiModels
  end

  describe 'uses entity as response object implicitly with route name' do
    subject do
      get '/swagger_doc/use-response'
      JSON.parse(last_response.body)
    end

    it 'returns openapi version' do
      expect(subject['openapi']).to eq('3.0.3')
    end

    it 'has operation with responses using components/schemas references' do
      operation = subject['paths']['/use-response']['get']

      expect(operation['description']).to eq('This returns something')
      expect(operation['tags']).to eq(['use-response'])
      expect(operation['operationId']).to eq('getUseResponse')
    end

    it 'has success response with schema reference in content' do
      response = subject['paths']['/use-response']['get']['responses']['200']

      expect(response['description']).to eq('This returns something')
      expect(response['content']).to eq({
        'application/json' => {
          'schema' => { '$ref' => '#/components/schemas/UseResponse' }
        }
      })
    end

    it 'has failure response without model (empty schema)' do
      response = subject['paths']['/use-response']['get']['responses']['400']

      expect(response['description']).to eq('NotFound')
      expect(response['content']).to be_nil
    end

    it 'has failure response with model' do
      response = subject['paths']['/use-response']['get']['responses']['404']

      expect(response['description']).to eq('BadRequest')
      expect(response['content']).to eq({
        'application/json' => {
          'schema' => { '$ref' => '#/components/schemas/ApiError' }
        }
      })
    end

    it 'has default response with model' do
      response = subject['paths']['/use-response']['get']['responses']['default']

      expect(response['description']).to eq('Error')
      expect(response['content']).to eq({
        'application/json' => {
          'schema' => { '$ref' => '#/components/schemas/ApiError' }
        }
      })
    end

    it 'defines schemas in components/schemas instead of definitions' do
      expect(subject['definitions']).to be_nil
      expect(subject['components']['schemas']).to include('UseResponse', 'ApiError')
    end

    it 'does not have produces at operation level' do
      operation = subject['paths']['/use-response']['get']
      expect(operation['produces']).to be_nil
    end
  end
end
