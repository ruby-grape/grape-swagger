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
             ],
             default_response: { message: 'Error', model: Entities::ApiError }
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
          '404' => { 'description' => 'BadRequest', 'schema' => { '$ref' => '#/definitions/ApiError' } },
          'default' => { 'description' => 'Error', 'schema' => { '$ref' => '#/definitions/ApiError' } }
        },
        'tags' => ['use-response'],
        'operationId' => 'getUseResponse'
      )
      expect(subject['definitions']).to eql(swagger_entity_as_response_object)
    end
  end

  # Grape HEAD remaps `default:` onto `default_response:` and warns; this
  # example is the released-Grape README spelling that grape-swagger used to ignore.
  describe 'uses the documented default: spelling', unless: GrapeVersion.default_response_in_dsl? do
    before :all do
      module TheApi
        class ResponseApiDefaultAlias < Grape::API
          format :json

          desc 'This returns something',
               success: [{ code: 200 }],
               default: { message: 'Error', model: Entities::ApiError }
          get '/use-default' do
            { 'declared_params' => declared(params) }
          end

          add_swagger_documentation(models: [Entities::UseResponse])
        end
      end
    end

    def app
      TheApi::ResponseApiDefaultAlias
    end

    subject do
      get '/swagger_doc/use-default'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/use-default']['get']['responses']['default']).to eql(
        'description' => 'Error',
        'schema' => { '$ref' => '#/definitions/ApiError' }
      )
    end
  end
end
