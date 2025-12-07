# frozen_string_literal: true

require 'spec_helper'

describe 'Response headers in OpenAPI 3.0' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class ResponseHeadersOAS3Api < Grape::API
        format :json

        desc 'Endpoint with response headers' do
          success model: Entities::UseResponse, headers: {
            'X-Request-Id' => { description: 'Request identifier', type: 'string' },
            'X-Rate-Limit' => { description: 'Rate limit remaining', type: 'integer' }
          }
          failure [
            [404, 'Not Found', Entities::ApiError, nil, { 'X-Error-Code' => { description: 'Error code', type: 'string' } }]
          ]
        end
        get '/with_headers' do
          { data: 'response' }
        end

        add_swagger_documentation(openapi_version: '3.0')
      end
    end
  end

  def app
    TheApi::ResponseHeadersOAS3Api
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'success response headers' do
    let(:success_response) { subject['paths']['/with_headers']['get']['responses']['200'] }

    it 'includes headers in response' do
      expect(success_response).to have_key('headers')
    end

    it 'wraps header type in schema for OAS3' do
      request_id_header = success_response['headers']['X-Request-Id']
      expect(request_id_header).to have_key('schema')
      expect(request_id_header['schema']['type']).to eq('string')
    end

    it 'includes header description' do
      request_id_header = success_response['headers']['X-Request-Id']
      expect(request_id_header['description']).to eq('Request identifier')
    end

    it 'handles integer type headers' do
      rate_limit_header = success_response['headers']['X-Rate-Limit']
      expect(rate_limit_header['schema']['type']).to eq('integer')
    end
  end

  describe 'error response headers' do
    let(:error_response) { subject['paths']['/with_headers']['get']['responses']['404'] }

    it 'includes headers in error response' do
      expect(error_response).to have_key('headers')
    end

    it 'wraps error header type in schema' do
      error_header = error_response['headers']['X-Error-Code']
      expect(error_header).to have_key('schema')
      expect(error_header['schema']['type']).to eq('string')
    end
  end
end
