# frozen_string_literal: true

require 'spec_helper'

describe 'response with headers' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class ResponseApiHeaders < Grape::API
        format :json

        desc 'This returns headers' do
          success model: Entities::UseResponse, headers: { 'Location' => { description: 'Location of resource', type: 'string' } }
          failure [[404, 'NotFound', Entities::ApiError, { 'application/json' => { code: 404, message: 'Not found' } }, { 'Date' => { description: 'Date of failure', type: 'string' } }]]
        end
        get '/response_headers' do
          { 'declared_params' => declared(params) }
        end

        desc 'A 204 can have headers too' do
          success Hash[status: 204, message: 'No content', headers: { 'Location' => { description: 'Location of resource', type: 'string' } }]
          failure [[400, 'Bad Request', Entities::ApiError, { 'application/json' => { code: 400, message: 'Bad request' } }, { 'Date' => { description: 'Date of failure', type: 'string' } }]]
        end
        delete '/no_content_response_headers' do
          { 'declared_params' => declared(params) }
        end

        desc 'A file can have headers too' do
          success Hash[status: 200, model: 'File', headers: { 'Cache-Control' => { description: 'Directive for caching', type: 'string' } }]
          failure [[404, 'NotFound', Entities::ApiError, { 'application/json' => { code: 404, message: 'Not found' } }, { 'Date' => { description: 'Date of failure', type: 'string' } }]]
        end
        get '/file_response_headers' do
          { 'declared_params' => declared(params) }
        end

        desc 'This syntax also returns headers' do
          success model: Entities::UseResponse, headers: { 'Location' => { description: 'Location of resource', type: 'string' } }
          failure [
            {
              code: 404,
              message: 'NotFound',
              model: Entities::ApiError,
              headers: { 'Date' => { description: 'Date of failure', type: 'string' } }
            },
            {
              code: 400,
              message: 'BadRequest',
              model: Entities::ApiError,
              headers: { 'Date' => { description: 'Date of failure', type: 'string' } }
            }
          ]
        end
        get '/response_failure_headers' do
          { 'declared_params' => declared(params) }
        end

        desc 'This does not return headers' do
          success model: Entities::UseResponse
          failure [[404, 'NotFound', Entities::ApiError]]
        end
        get '/response_no_headers' do
          { 'declared_params' => declared(params) }
        end
        add_swagger_documentation openapi_version: '3.0'
      end
    end
  end

  def app
    TheApi::ResponseApiHeaders
  end

  describe 'response headers' do
    let(:header_200) do
      { 'Location' => { 'description' => 'Location of resource', 'type' => 'string' } }
    end
    let(:header_404) do
      { 'Date' => { 'description' => 'Date of failure', 'type' => 'string' } }
    end
    let(:examples_404) do
      { 'application/json' => { 'code' => 404, 'message' => 'Not found' } }
    end

    subject do
      get '/swagger_doc/response_headers'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/response_headers']['get']).to eql(
        'description' => 'This returns headers',
        'operationId' => 'getResponseHeaders',
        'tags' => ['response_headers'],
        'responses' => {
          '200' => {
            'content' => {
              'application/json' => {
                'schema' => { '$ref' => '#/components/schemas/UseResponse' }
              }
            },
            'description' => 'This returns headers',
            'headers' => {
              'Location' => {
                'description' => 'Location of resource',
                'schema' => { 'type' => 'string' }
              }
            }
          },
          '404' => {
            'content' => {
              'application/json' => {
                'example' => {
                  'code' => 404,
                  'message' => 'Not found'
                },
                'schema' => { '$ref' => '#/components/schemas/ApiError' }
              }
            },
            'description' => 'NotFound',
            'headers' => {
              'Date' => {
                'description' => 'Date of failure',
                'schema' => { 'type' => 'string' }
              }
            }
          }
        }
      )
    end
  end

  describe 'no content response headers' do
    let(:header_204) do
      { 'Location' => { 'description' => 'Location of resource', 'type' => 'string' } }
    end
    let(:header_400) do
      { 'Date' => { 'description' => 'Date of failure', 'type' => 'string' } }
    end
    let(:examples_400) do
      { 'application/json' => { 'code' => 400, 'message' => 'Bad request' } }
    end

    subject do
      get '/swagger_doc/no_content_response_headers', {}
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/no_content_response_headers']['delete']).to eql(
        'description' => 'A 204 can have headers too',
        'responses' => {
          '204' => {
            'description' => 'No content',
            'headers' => {
              'Location' => {
                'description' => 'Location of resource', 'schema' => { 'type' => 'string' }
              }
            }
          },
          '400' => {
            'content' => {
              'application/json' => {
                'example' => { 'code' => 400, 'message' => 'Bad request' },
                'schema' => { '$ref' => '#/components/schemas/ApiError' }
              }
            },
            'description' => 'Bad Request',
            'headers' => { 'Date' => { 'description' => 'Date of failure', 'schema' => { 'type' => 'string' } } }
          }
        },
        'tags' => ['no_content_response_headers'],
        'operationId' => 'deleteNoContentResponseHeaders'
      )
    end
  end

  describe 'file response headers' do
    let(:header_200) do
      { 'Cache-Control' => { 'description' => 'Directive for caching', 'type' => 'string' } }
    end
    let(:header_404) do
      { 'Date' => { 'description' => 'Date of failure', 'type' => 'string' } }
    end
    let(:examples_404) do
      { 'application/json' => { 'code' => 404, 'message' => 'Not found' } }
    end

    subject do
      get '/swagger_doc/file_response_headers'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/file_response_headers']['get']).to eql(
        'description' => 'A file can have headers too',
        'responses' => {
          '200' => {
            'content' => {
              'application/octet-stream' => { 'schema' => {} }
            },
            'description' => 'A file can have headers too',
            'headers' => {
              'Cache-Control' => { 'description' => 'Directive for caching', 'schema' => { 'type' => 'string' } }
            }
          },
          '404' => {
            'content' => {
              'application/json' => {
                'example' => { 'code' => 404, 'message' => 'Not found' },
                'schema' => { '$ref' => '#/components/schemas/ApiError' }
              }
            },
            'description' => 'NotFound',
            'headers' => {
              'Date' => { 'description' => 'Date of failure', 'schema' => { 'type' => 'string' } }
            }
          }
        },
        'tags' => ['file_response_headers'],
        'operationId' => 'getFileResponseHeaders'
      )
    end
  end

  describe 'response failure headers' do
    let(:header_200) do
      { 'Location' => { 'description' => 'Location of resource', 'schema' => { 'type' => 'string' } } }
    end
    let(:header_404) do
      { 'Date' => { 'description' => 'Date of failure', 'schema' => { 'type' => 'string' } } }
    end
    let(:header_400) do
      { 'Date' => { 'description' => 'Date of failure', 'schema' => { 'type' => 'string' } } }
    end

    subject do
      get '/swagger_doc/response_failure_headers'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/response_failure_headers']['get']).to eql(
        'description' => 'This syntax also returns headers',
        'operationId' => 'getResponseFailureHeaders',
        'responses' => {
          '200' => {
            'content' => {
              'application/json' => {
                'schema' => { '$ref' => '#/components/schemas/UseResponse' }
              }
            },
            'description' => 'This syntax also returns headers',
            'headers' => header_200
          },
          '400' => {
            'content' => {
              'application/json' => { 'schema' => { '$ref' => '#/components/schemas/ApiError' } }
            },
            'description' => 'BadRequest',
            'headers' => header_400
          },
          '404' => {
            'content' => {
              'application/json' => { 'schema' => { '$ref' => '#/components/schemas/ApiError' } }
            },
            'description' => 'NotFound',
            'headers' => header_404
          }
        },
        'tags' => ['response_failure_headers']
      )
    end
  end

  describe 'response no headers' do
    subject do
      get '/swagger_doc/response_no_headers'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/response_no_headers']['get']).to eql(
        'description' => 'This does not return headers',
        'responses' => {
          '200' => {
            'content' => {
              'application/json' => {
                'schema' => { '$ref' => '#/components/schemas/UseResponse' }
              }
            },
            'description' => 'This does not return headers'
          },
          '404' => {
            'content' => {
              'application/json' => {
                'schema' => { '$ref' => '#/components/schemas/ApiError' }
              }
            },
            'description' => 'NotFound'
          }
        },
        'tags' => ['response_no_headers'],
        'operationId' => 'getResponseNoHeaders'
      )
    end
  end
end
