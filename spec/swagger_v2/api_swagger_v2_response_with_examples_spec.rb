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

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::ResponseApiExamples
  end

  describe 'response examples' do
    let(:example_200) do
      { 'application/json' => { 'description' => 'Names list', 'items' => [{ 'id' => '123', 'name' => 'John' }] } }
    end
    let(:example_404) do
      { 'application/json' => { 'code' => 404, 'message' => 'Not found' } }
    end

    subject do
      get '/swagger_doc/response_examples'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/response_examples']['get']).to eql(
        'description' => 'This returns examples',
        'produces' => ['application/json'],
        'responses' => {
          '200' => { 'description' => 'This returns examples', 'schema' => { '$ref' => '#/definitions/UseResponse' }, 'examples' => example_200 },
          '404' => { 'description' => 'NotFound', 'schema' => { '$ref' => '#/definitions/ApiError' }, 'examples' => example_404 }
        },
        'tags' => ['response_examples'],
        'operationId' => 'getResponseExamples'
      )
    end
  end
end
