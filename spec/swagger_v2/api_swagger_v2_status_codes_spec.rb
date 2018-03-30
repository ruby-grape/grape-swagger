# frozen_string_literal: true

require 'spec_helper'

describe 'http status code behaviours' do
  include_context "#{MODEL_PARSER} swagger example"

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
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
        add_swagger_documentation
      end
    end

    it 'only includes the defined http_codes' do
      expect(subject['paths']['/accepting_endpoint']['post']['responses'].keys.sort).to eq(%w[202 204 400].sort)
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
        add_swagger_documentation
      end
    end

    it 'only includes the defined http codes' do
      expect(subject['paths']['/accepting_endpoint']['post']['responses'].keys.sort).to eq(%w[202 400].sort)
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
        add_swagger_documentation
      end
    end

    it 'adds the success codes to the response' do
      expect(subject['paths']['/error_endpoint']['post']['responses'].keys.sort).to eq(%w[201 400 404].sort)
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
        add_swagger_documentation
      end
    end

    it 'adds the success codes and error codes to the response' do
      expect(subject['paths']['/endpoint']['get']['responses'].keys.sort).to eq(%w[200 404].sort)
    end
  end
end
