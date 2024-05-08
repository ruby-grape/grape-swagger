# frozen_string_literal: true

require 'spec_helper'

describe 'response with examples' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class ResponseApiExamples < Grape::API
        format :json

        desc 'This returns examples' do
          success model: Entities::UseResponse, examples: { 'application/json' => { description: 'Names list', items: [{ id: '123', name: 'John' }] } }
          failure [[404, 'NotFound', Entities::ApiError, { 'application/json' => { code: 404, message: 'Not found' } }]]
        end
        get '/response_examples' do
          { 'declared_params' => declared(params) }
        end

        desc 'This returns multiple examples' do
          success model: Entities::UseResponse, examples: { 'foo' => { description: 'Names list', items: [{ id: '123', name: 'John' }] }, 'bar' => { description: 'Another list', items: [{ id: '123', something: 'John' }] } }
          failure [[404, 'NotFound', Entities::ApiError, { 'application/json' => { code: 404, message: 'Not found' } }]]
        end
        get '/response_multiple_examples' do
          { 'declared_params' => declared(params) }
        end

        desc 'This syntax also returns examples' do
          success model: Entities::UseResponse, examples: { 'application/json' => { description: 'Names list', items: [{ id: '123', name: 'John' }] } }
          failure [
            {
              code: 404,
              message: 'NotFound',
              model: Entities::ApiError,
              examples: { 'application/json' => { code: 404, message: 'Not found' } }
            },
            {
              code: 400,
              message: 'BadRequest',
              model: Entities::ApiError,
              examples: { 'application/json' => { code: 400, message: 'Bad Request' } }
            }
          ]
        end
        get '/response_failure_examples' do
          { 'declared_params' => declared(params) }
        end

        desc 'This does not return examples' do
          success model: Entities::UseResponse
          failure [[404, 'NotFound', Entities::ApiError]]
        end
        get '/response_no_examples' do
          { 'declared_params' => declared(params) }
        end
        add_swagger_documentation openapi_version: '3.0'
      end
    end
  end

  def app
    TheApi::ResponseApiExamples
  end

  describe 'response examples' do
    let(:example_200) { { 'description' => 'Names list', 'items' => [{ 'id' => '123', 'name' => 'John' }] } }
    let(:example_404) { { 'code' => 404, 'message' => 'Not found' } }

    subject do
      get '/swagger_doc/response_examples'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/response_examples']['get']).to eql(
        'description' => 'This returns examples',
        'responses' => {
          '200' => {
            'content' => {
              'application/json' => {
                'example' => example_200,
                'schema' => { '$ref' => '#/components/schemas/UseResponse' }
              }
            },
            'description' => 'This returns examples'
          },
          '404' => {
            'content' => {
              'application/json' => {
                'example' => example_404,
                'schema' => { '$ref' => '#/components/schemas/ApiError' }
              }
            },
            'description' => 'NotFound'
          }
        },
        'tags' => ['response_examples'],
        'operationId' => 'getResponseExamples'
      )
    end
  end

  describe 'response multiple examples' do
    let(:example_200) do
      {
        'bar' => { 'value' => { 'description' => 'Another list', 'items' => [{ 'id' => '123', 'something' => 'John' }] } },
        'foo' => { 'value' => { 'description' => 'Names list', 'items' => [{ 'id' => '123', 'name' => 'John' }] } }
      }
    end
    let(:example_404) { { 'code' => 404, 'message' => 'Not found' } }

    subject do
      get '/swagger_doc/response_multiple_examples'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/response_multiple_examples']['get']).to eql(
        'description' => 'This returns multiple examples',
        'responses' => {
          '200' => {
            'content' => {
              'application/json' => {
                'examples' => example_200,
                'schema' => { '$ref' => '#/components/schemas/UseResponse' }
              }
            },
            'description' => 'This returns multiple examples'
          },
          '404' => {
            'content' => {
              'application/json' => {
                'example' => example_404,
                'schema' => { '$ref' => '#/components/schemas/ApiError' }
              }
            },
            'description' => 'NotFound'
          }
        },
        'tags' => ['response_multiple_examples'],
        'operationId' => 'getResponseMultipleExamples'
      )
    end
  end

  describe 'response failure examples' do
    let(:example_200) do
      { 'application/json' => { 'description' => 'Names list', 'items' => [{ 'id' => '123', 'name' => 'John' }] } }
    end
    let(:example_404) do
      { 'application/json' => { 'code' => 404, 'message' => 'Not found' } }
    end
    let(:example_400) do
      { 'application/json' => { 'code' => 400, 'message' => 'Bad Request' } }
    end

    subject do
      get '/swagger_doc/response_failure_examples'
      puts last_response.body
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/response_failure_examples']['get']).to eql(
        'description' => 'This syntax also returns examples',
        'responses' => {
          '200' => {
            'content' => {
              'application/json' => {
                'example' => { 'description' => 'Names list', 'items' => [{ 'id' => '123', 'name' => 'John' }] },
                'schema' => { '$ref' => '#/components/schemas/UseResponse' }
              }
            },
            'description' => 'This syntax also returns examples'
          },
          '400' => {
            'content' => {
              'application/json' => {
                'example' => { 'code' => 400, 'message' => 'Bad Request' },
                'schema' => { '$ref' => '#/components/schemas/ApiError' }
              }
            },
            'description' => 'BadRequest'
          },
          '404' => {
            'content' => {
              'application/json' => {
                'example' => { 'code' => 404, 'message' => 'Not found' },
                'schema' => { '$ref' => '#/components/schemas/ApiError' }
              }
            },
            'description' => 'NotFound'
          }
        },
        'tags' => ['response_failure_examples'],
        'operationId' => 'getResponseFailureExamples'
      )
    end
  end

  describe 'response no examples' do
    subject do
      get '/swagger_doc/response_no_examples'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/response_no_examples']['get']).to eql(
        'description' => 'This does not return examples',
        'responses' => {
          '200' => {
            'content' => {
              'application/json' => { 'schema' => { '$ref' => '#/components/schemas/UseResponse' } }
            },
            'description' => 'This does not return examples'
          },
          '404' => {
            'content' => {
              'application/json' => { 'schema' => { '$ref' => '#/components/schemas/ApiError' } }
            },
            'description' => 'NotFound'
          }
        },
        'tags' => ['response_no_examples'],
        'operationId' => 'getResponseNoExamples'
      )
    end
  end
end
