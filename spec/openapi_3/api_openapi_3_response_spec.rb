# frozen_string_literal: true

require 'spec_helper'

describe 'response' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class ResponseApi < Grape::API
        format :json

        desc 'This returns something',
             params: Entities::UseResponse.documentation,
             failure: [{ code: 400, message: 'NotFound', model: Entities::ApiError }]
        post '/params_given' do
          { 'declared_params' => declared(params) }
        end

        desc 'This returns something',
             entity: Entities::UseResponse,
             failure: [{ code: 400, message: 'NotFound', model: Entities::ApiError }]
        get '/entity_response' do
          { 'declared_params' => declared(params) }
        end

        desc 'This returns something',
             entity: Entities::UseItemResponseAsType,
             failure: [{ code: 400, message: 'NotFound', model: Entities::ApiError }]
        get '/nested_type' do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation openapi_version: '3.0'
      end
    end
  end

  def app
    TheApi::ResponseApi
  end

  describe 'uses nested type as response object' do
    subject do
      get '/swagger_doc/nested_type'
      JSON.parse(last_response.body)
    end
    specify do
      expect(subject['paths']['/nested_type']['get']).to eql(
        'description' => 'This returns something',
        'responses' => {
          '200' => {
            'description' => 'This returns something',
            'content' => {
              'application/json' => {
                'schema' => { '$ref' => '#/components/schemas/UseItemResponseAsType' }
              }
            }
          },
          '400' => {
            'description' => 'NotFound',
            'content' => {
              'application/json' => {
                'schema' => { '$ref' => '#/components/schemas/ApiError' }
              }
            }
          }
        },
        'tags' => ['nested_type'],
        'operationId' => 'getNestedType'
      )
      expect(subject['components']['schemas']).to eql(swagger_nested_type)
    end
  end

  describe 'uses entity as response object' do
    subject do
      get '/swagger_doc/entity_response'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/entity_response']['get']).to eql(
        'description' => 'This returns something',
        'responses' => {
          '200' => {
            'description' => 'This returns something',
            'content' => {
              'application/json' => {
                'schema' => { '$ref' => '#/components/schemas/UseResponse' }
              }
            }
          },
          '400' => {
            'description' => 'NotFound',
            'content' => {
              'application/json' => {
                'schema' => { '$ref' => '#/components/schemas/ApiError' }
              }
            }
          }
        },
        'tags' => ['entity_response'],
        'operationId' => 'getEntityResponse'
      )
      expect(subject['components']['schemas']).to eql(swagger_entity_as_response_object)
    end
  end

  describe 'uses params as response object' do
    subject do
      get '/swagger_doc/params_given'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/params_given']['post']).to eql(
        'description' => 'This returns something',
        'requestBody' => {
          'content' => {
            'application/x-www-form-urlencoded' => {
              'schema' => {
                'properties' => {
                  '$responses' => {
                    'items' => { 'type' => 'string' }, 'type' => 'array'
                  },
                  'description' => { 'type' => 'string' }
                },
                'type' => 'object'
              }
            }
          }
        },
        'responses' => {
          '201' => {
            'description' => 'This returns something'
          },
          '400' => {
            'description' => 'NotFound',
            'content' => {
              'application/json' => {
                'schema' => { '$ref' => '#/components/schemas/ApiError' }
              }
            }
          }
        },
        'tags' => ['params_given'],
        'operationId' => 'postParamsGiven'
      )
      expect(subject['components']['schemas']).to eql(swagger_params_as_response_object)
    end
  end
end
