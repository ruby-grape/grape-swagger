# frozen_string_literal: true

require 'spec_helper'

describe 'response with headers' do
  # include_context "#{MODEL_PARSER} swagger header"

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
          foo = { status: 204, message: 'No content', headers: { 'Location' => { description: 'Location of resource', type: 'string' } } }
          success foo
          failure [[400, 'Bad Request', Entities::ApiError, { 'application/json' => { code: 400, message: 'Bad request' } }, { 'Date' => { description: 'Date of failure', type: 'string' } }]]
        end
        delete '/no_content_response_headers' do
          { 'declared_params' => declared(params) }
        end

        desc 'A file can have headers too' do
          foo = { status: 200, model: 'File', headers: { 'Cache-Control': { description: 'Directive for caching', type: 'string' } } }
          success foo
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
        add_swagger_documentation
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
        'produces' => ['application/json'],
        'responses' => {
          '200' => { 'description' => 'This returns headers', 'schema' => { '$ref' => '#/definitions/UseResponse' }, 'headers' => header_200 },
          '404' => { 'description' => 'NotFound', 'schema' => { '$ref' => '#/definitions/ApiError' }, 'examples' => examples_404, 'headers' => header_404 }
        },
        'tags' => ['response_headers'],
        'operationId' => 'getResponseHeaders'
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
        'produces' => ['application/json'],
        'responses' => {
          '204' => { 'description' => 'No content', 'headers' => header_204 },
          '400' => { 'description' => 'Bad Request', 'headers' => header_400, 'schema' => { '$ref' => '#/definitions/ApiError' }, 'examples' => examples_400 }
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
        'produces' => ['application/json'],
        'responses' => {
          '200' => { 'description' => 'A file can have headers too', 'headers' => header_200, 'schema' => { 'type' => 'file' } },
          '404' => { 'description' => 'NotFound', 'headers' => header_404, 'schema' => { '$ref' => '#/definitions/ApiError' }, 'examples' => examples_404 }
        },
        'tags' => ['file_response_headers'],
        'operationId' => 'getFileResponseHeaders'
      )
    end
  end

  describe 'response failure headers' do
    let(:header_200) do
      { 'Location' => { 'description' => 'Location of resource', 'type' => 'string' } }
    end
    let(:header_404) do
      { 'Date' => { 'description' => 'Date of failure', 'type' => 'string' } }
    end
    let(:header_400) do
      { 'Date' => { 'description' => 'Date of failure', 'type' => 'string' } }
    end

    subject do
      get '/swagger_doc/response_failure_headers'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/response_failure_headers']['get']).to eql(
        'description' => 'This syntax also returns headers',
        'produces' => ['application/json'],
        'responses' => {
          '200' => { 'description' => 'This syntax also returns headers', 'schema' => { '$ref' => '#/definitions/UseResponse' }, 'headers' => header_200 },
          '404' => { 'description' => 'NotFound', 'schema' => { '$ref' => '#/definitions/ApiError' }, 'headers' => header_404 },
          '400' => { 'description' => 'BadRequest', 'schema' => { '$ref' => '#/definitions/ApiError' }, 'headers' => header_400 }
        },
        'tags' => ['response_failure_headers'],
        'operationId' => 'getResponseFailureHeaders'
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
        'produces' => ['application/json'],
        'responses' => {
          '200' => { 'description' => 'This does not return headers', 'schema' => { '$ref' => '#/definitions/UseResponse' } },
          '404' => { 'description' => 'NotFound', 'schema' => { '$ref' => '#/definitions/ApiError' } }
        },
        'tags' => ['response_no_headers'],
        'operationId' => 'getResponseNoHeaders'
      )
    end
  end
end
