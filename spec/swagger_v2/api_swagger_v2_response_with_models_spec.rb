# frozen_string_literal: true

require 'spec_helper'

describe 'response' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class ResponseApiModels < Grape::API
        format :json

        desc 'This returns something',
             success: [{ code: 200 }],
             failure: [
               { code: 400, message: 'NotFound', model: '' },
               { code: 404, message: 'BadRequest', model: Entities::ApiError }
             ]
        get '/use-response' do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation(models: [Entities::UseResponse])
      end
    end
  end

  def app
    TheApi::ResponseApiModels
  end

  describe 'uses entity as response object implicitly with route name' do
    subject do
      get '/swagger_doc/use-response'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/use-response']['get']).to eql(
        'description' => 'This returns something',
        'produces' => ['application/json'],
        'responses' => {
          '200' => { 'description' => 'This returns something', 'schema' => { '$ref' => '#/definitions/UseResponse' } },
          '400' => { 'description' => 'NotFound' },
          '404' => { 'description' => 'BadRequest', 'schema' => { '$ref' => '#/definitions/ApiError' } }
        },
        'tags' => ['use-response'],
        'operationId' => 'getUseResponse'
      )
      expect(subject['definitions']).to eql(swagger_entity_as_response_object)
    end
  end
end
