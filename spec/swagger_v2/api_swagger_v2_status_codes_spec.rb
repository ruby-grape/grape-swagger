# frozen_string_literal: true

require 'spec_helper'

describe 'http status code behaivours' do
  include_context "#{MODEL_PARSER} swagger example"

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  context 'when non-default success codes are deifined' do
    let(:app) do
      Class.new(Grape::API) do
        desc 'Has explicit http_codes defined' do
          http_codes [{ code: 202, message: 'We got it!' },
                      { code: 204, message: 'Or returned no content' }]
        end

        post '/accepting_endpoint' do
          'We got the message!'
        end
        add_swagger_documentation
      end
    end

    it 'only includes the defined http_codes' do
      expect(subject['paths']['/accepting_endpoint']['post']['responses'].keys.sort).to eq(%w[202 204].sort)
    end
  end

  context 'when no success codes defined' do
    let(:app) do
      Class.new(Grape::API) do
        desc 'Has explicit http_codes defined' do
          http_codes [{ code: 400, message: 'Error!' },
                      { code: 404, message: 'Not found' }]
        end

        post '/accepting_endpoint' do
          'We got the message!'
        end
        add_swagger_documentation
      end
    end

    it 'adds the success code to the response' do
      expect(subject['paths']['/accepting_endpoint']['post']['responses'].keys.sort).to eq(%w[201 400 404].sort)
    end
  end
end
