# frozen_string_literal: true

require 'spec_helper'

describe 'Params Types' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :input, type: String
      end
      post :action do
      end

      params do
        requires :input, type: String, default: '14', documentation: { type: 'email', default: '42' }
      end
      post :action_with_doc do
      end

      add_swagger_documentation openapi_version: '3.0'
    end
  end
  context 'with no documentation hash' do
    subject do
      get '/swagger_doc/action'
      expect(last_response.status).to eq 200
      body = JSON.parse last_response.body
      body['paths']['/action']['post']
    end

    it 'reads param type correctly' do
      expect(subject['requestBody']).to eq 'content' => {
        'application/json' => { 'schema' => { 'properties' => {}, 'type' => 'object' } },
        'application/x-www-form-urlencoded' => {
          'schema' => {
            'properties' => {
              'input' => { 'type' => 'string' }
            },
            'required' => ['input'],
            'type' => 'object'
          }
        }
      }
    end

    describe 'header params' do
      def app
        Class.new(Grape::API) do
          format :json

          desc 'Some API', headers: { 'My-Header' => { required: true, description: 'Set this!' } }
          params do
            requires :input, type: String
          end
          post :action do
          end

          add_swagger_documentation openapi_version: '3.0'
        end
      end

      it 'has consistent types' do
        parameter_type = subject['parameters'].map { |param| param['schema']['type'] }
        expect(parameter_type).to eq(%w[string])

        header_type = subject['requestBody']['content']['application/x-www-form-urlencoded']['schema']['properties'].values.map { |param| param['type'] }
        expect(header_type).to eq(%w[string])
      end
    end
  end

  context 'with documentation hash' do
    subject do
      get '/swagger_doc/action_with_doc'
      expect(last_response.status).to eq 200
      body = JSON.parse last_response.body
      body['paths']['/action_with_doc']['post']['requestBody']
    end

    it 'reads param type correctly' do
      expect(subject).to eq 'content' => {
        'application/json' => { 'schema' => { 'properties' => {}, 'type' => 'object' } },
        'application/x-www-form-urlencoded' => {
          'schema' => {
            'properties' => {
              'input' => { 'default' => '42', 'format' => 'email', 'type' => 'string' }
            },
            'required' => ['input'], 'type' => 'object'
          }
        }
      }
    end
  end
end
