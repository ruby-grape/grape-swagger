# frozen_string_literal: true

require 'spec_helper'

describe 'Params Multi Types' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        if Grape::VERSION < '0.14'
          requires :input, type: [String, Integer]
        else
          requires :input, types: [String, Integer]
        end
        requires :another_input, type: [String, Integer]
      end
      post :action do
      end

      add_swagger_documentation openapi_version: '3.0'
    end
  end

  subject do
    get '/swagger_doc/action'
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    body['paths']['/action']['post']
  end

  it 'reads request body type correctly' do
    expect(subject['requestBody']['content']).to eq('application/x-www-form-urlencoded' => {
      'schema' => {
        'properties' => { 'another_input' => { 'type' => 'string' }, 'input' => { 'type' => 'string' } },
        'required' => %w[input another_input],
        'type' => 'object'
      }
    })
  end

  describe 'header params' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Some API', headers: { 'My-Header' => { required: true, description: 'Set this!' } }
        params do
          if Grape::VERSION < '0.14'
            requires :input, type: [String, Integer]
          else
            requires :input, types: [String, Integer]
          end
          requires :another_input, type: [String, Integer]
        end
        post :action do
        end

        add_swagger_documentation openapi_version: '3.0'
      end
    end

    it 'reads parameter type correctly' do
      expect(subject['parameters']).to eq([{
        'description' => 'Set this!',
        'in' => 'header',
        'name' => 'My-Header',
        'required' => true,
        'schema' => { 'type' => 'string' }
      }])
    end

    it 'has consistent types' do
      request_body_types = subject['requestBody']['content']['application/x-www-form-urlencoded']['schema']['properties'].values.map { |param| param['type'] }
      expect(request_body_types).to eq(%w[string string])

      request_body_types = subject['parameters'].map { |param| param['schema']['type'] }
      expect(request_body_types).to eq(%w[string])
    end
  end
end
