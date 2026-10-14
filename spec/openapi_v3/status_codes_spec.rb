# frozen_string_literal: true

require 'spec_helper'

describe 'HTTP status code handling in OAS 3.0' do
  include_context "#{MODEL_PARSER} swagger example"

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'OAS3 format verification' do
    let(:app) do
      Class.new(Grape::API) do
        desc 'Simple endpoint'
        get '/test' do
          {}
        end
        add_swagger_documentation openapi_version: '3.0'
      end
    end

    it 'returns openapi 3.0.3' do
      expect(subject['openapi']).to eq('3.0.3')
    end
  end

  context 'when non-default success codes are defined' do
    let(:app) do
      Class.new(Grape::API) do
        desc 'Has explicit success http_codes defined' do
          http_codes [{ code: 202, message: 'We got it!' },
                      { code: 204, message: 'Or returned no content' },
                      { code: 400, message: 'Bad request' }]
        end

        post '/accepting_endpoint' do
          'We got the message!'
        end
        add_swagger_documentation openapi_version: '3.0'
      end
    end

    it 'only includes the defined http_codes' do
      response_codes = subject['paths']['/accepting_endpoint']['post']['responses'].keys
      expect(response_codes.sort).to eq(%w[202 204 400].sort)
    end

    it 'responses have proper OAS3 structure' do
      responses = subject['paths']['/accepting_endpoint']['post']['responses']
      expect(responses['202']['description']).to eq('We got it!')
      expect(responses['204']['description']).to eq('Or returned no content')
      expect(responses['400']['description']).to eq('Bad request')
    end
  end

  context 'when success and failures are defined' do
    let(:app) do
      Class.new(Grape::API) do
        desc 'Has explicit success http_codes defined' do
          success code: 202, model: Entities::UseResponse, message: 'a changed status code'
          failure [[400, 'Bad Request']]
        end

        post '/accepting_endpoint' do
          'We got the message!'
        end
        add_swagger_documentation openapi_version: '3.0'
      end
    end

    it 'only includes the defined http codes' do
      response_codes = subject['paths']['/accepting_endpoint']['post']['responses'].keys
      expect(response_codes.sort).to eq(%w[202 400].sort)
    end

    it 'success response has content with schema ref' do
      response = subject['paths']['/accepting_endpoint']['post']['responses']['202']
      expect(response['content']['application/json']['schema']['$ref']).to eq(
        '#/components/schemas/UseResponse'
      )
    end

    it 'failure response has description' do
      response = subject['paths']['/accepting_endpoint']['post']['responses']['400']
      expect(response['description']).to eq('Bad Request')
    end
  end

  context 'when no success codes defined' do
    let(:app) do
      Class.new(Grape::API) do
        desc 'Has explicit error http_codes defined' do
          http_codes [{ code: 400, message: 'Error!' },
                      { code: 404, message: 'Not found' }]
        end

        post '/error_endpoint' do
          'We got the message!'
        end
        add_swagger_documentation openapi_version: '3.0'
      end
    end

    it 'adds default success code to the response' do
      response_codes = subject['paths']['/error_endpoint']['post']['responses'].keys
      expect(response_codes.sort).to eq(%w[201 400 404].sort)
    end
  end

  context 'when success and error codes are defined' do
    let(:app) do
      Class.new(Grape::API) do
        desc 'Has success and error codes defined' do
          http_codes [{ code: 200, message: 'Found' },
                      { code: 404, message: 'Not found' }]
        end

        get '/endpoint' do
          'We got the message!'
        end
        add_swagger_documentation openapi_version: '3.0'
      end
    end

    it 'includes both success and error codes' do
      response_codes = subject['paths']['/endpoint']['get']['responses'].keys
      expect(response_codes.sort).to eq(%w[200 404].sort)
    end

    it 'responses have descriptions' do
      responses = subject['paths']['/endpoint']['get']['responses']
      expect(responses['200']['description']).to eq('Found')
      expect(responses['404']['description']).to eq('Not found')
    end
  end

  context 'DELETE endpoint default status code' do
    let(:app) do
      Class.new(Grape::API) do
        desc 'Delete something'
        delete '/resource/:id' do
          {}
        end
        add_swagger_documentation openapi_version: '3.0'
      end
    end

    it 'uses 204 as default for DELETE' do
      response_codes = subject['paths']['/resource/{id}']['delete']['responses'].keys
      expect(response_codes).to include('204')
    end
  end

  context 'POST endpoint default status code' do
    let(:app) do
      Class.new(Grape::API) do
        desc 'Create something'
        post '/resource' do
          {}
        end
        add_swagger_documentation openapi_version: '3.0'
      end
    end

    it 'uses 201 as default for POST' do
      response_codes = subject['paths']['/resource']['post']['responses'].keys
      expect(response_codes).to include('201')
    end
  end
end
