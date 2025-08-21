# frozen_string_literal: true

require 'spec_helper'

describe 'response' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class ResponseApiModelsAndPrimitiveTypes < Grape::API
        format :json

        desc 'This returns something',
             success: [
               { type: 'Integer', as: :integer_response },
               { model: Entities::UseResponse, as: :user_response },
               { type: 'String', as: :string_response },
               { type: 'Float', as: :float_response },
               { type: 'Hash', as: :hash_response },
               { type: Array[Integer], as: :array_of_integer_response },
               { type: Array[String], as: :array_of_string_response },
               { type: Array[Float], as: :array_of_float_response },
               { type: Array[Hash], as: :array_of_hash_response },
               { type: Array[Array[Float]], as: :array_of_array_of_float_response }
             ],
             failure: [
               { code: 400, message: 'NotFound', model: '' },
               { code: 404, message: 'BadRequest', model: Entities::ApiError }
             ],
             default_response: { message: 'Error', model: Entities::ApiError }
        get '/use-response' do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::ResponseApiModelsAndPrimitiveTypes
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
          '200' => {
            'description' => 'This returns something',
            'schema' => {
              'type' => 'object',
              'properties' => {
                'user_response' => { '$ref' => '#/definitions/UseResponse' },
                'integer_response' => { 'type' => 'integer', 'format' => 'int32' },
                'string_response' => { 'type' => 'string' },
                'float_response' => { 'type' => 'number', 'format' => 'float' },
                'hash_response' => { 'type' => 'object' },
                'array_of_integer_response' => {
                  'type' => 'array',
                  'items' => {
                    'type' => 'integer',
                    'format' => 'int32'
                  }
                },
                'array_of_string_response' => {
                  'type' => 'array',
                  'items' => {
                    'type' => 'string'
                  }
                },
                'array_of_float_response' => {
                  'type' => 'array',
                  'items' => {
                    'type' => 'number',
                    'format' => 'float'
                  }
                },
                'array_of_hash_response' => {
                  'type' => 'array',
                  'items' => {
                    'type' => 'object'
                  }
                },
                'array_of_array_of_float_response' => {
                  'type' => 'array',
                  'items' => {
                    'type' => 'array',
                    'items' => {
                      'type' => 'number',
                      'format' => 'float'
                    }
                  }
                }
              }
            }
          },
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
end
