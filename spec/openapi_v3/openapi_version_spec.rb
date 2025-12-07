# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI version configuration' do
  describe 'default (Swagger 2.0)' do
    before :all do
      module TheApi
        class Swagger20Api < Grape::API
          format :json

          desc 'Get something'
          get '/something' do
            { id: 1, name: 'Test' }
          end

          desc 'Create something'
          params do
            requires :name, type: String, desc: 'Name of the thing'
            optional :description, type: String, desc: 'Description'
          end
          post '/something' do
            { id: 1, name: params[:name] }
          end

          add_swagger_documentation
        end
      end
    end

    def app
      TheApi::Swagger20Api
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'returns swagger 2.0 format' do
      expect(subject['swagger']).to eq '2.0'
      expect(subject).not_to have_key('openapi')
    end

    it 'does not have components' do
      expect(subject).not_to have_key('components')
    end
  end

  describe 'OpenAPI 3.0' do
    before :all do
      module TheApi
        class OAS30Api < Grape::API
          format :json

          desc 'Get something'
          get '/something' do
            { id: 1, name: 'Test' }
          end

          desc 'Create something'
          params do
            requires :name, type: String, desc: 'Name of the thing'
            optional :description, type: String, desc: 'Description'
          end
          post '/something' do
            { id: 1, name: params[:name] }
          end

          desc 'Update something'
          params do
            requires :id, type: Integer, desc: 'ID of the thing'
            requires :name, type: String, desc: 'Name of the thing'
          end
          put '/something/:id' do
            { id: params[:id], name: params[:name] }
          end

          add_swagger_documentation(openapi_version: '3.0')
        end
      end
    end

    def app
      TheApi::OAS30Api
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'returns openapi 3.0 format' do
      expect(subject['openapi']).to eq '3.0.3'
      expect(subject).not_to have_key('swagger')
    end

    it 'has components section' do
      expect(subject).to have_key('components')
    end

    it 'uses requestBody instead of body parameters' do
      post_op = subject['paths']['/something']['post']
      expect(post_op).to have_key('requestBody')
      body_params = (post_op['parameters'] || []).select { |p| p['in'] == 'body' }
      expect(body_params).to be_empty
    end

    it 'wraps parameters in schema' do
      put_op = subject['paths']['/something/{id}']['put']
      path_params = put_op['parameters'].select { |p| p['in'] == 'path' }

      path_params.each do |param|
        expect(param).to have_key('schema')
        expect(param['schema']).to have_key('type')
      end
    end

    it 'uses content wrappers in requestBody' do
      post_op = subject['paths']['/something']['post']
      expect(post_op['requestBody']).to have_key('content')
    end

    it 'converts refs to components path' do
      json_string = subject.to_json
      expect(json_string).not_to include('#/definitions/')
    end
  end

  describe 'OpenAPI 3.1' do
    before :all do
      module TheApi
        class OAS31Api < Grape::API
          format :json

          desc 'Get something'
          get '/something' do
            { id: 1, name: 'Test' }
          end

          desc 'Create something'
          params do
            requires :name, type: String, desc: 'Name of the thing'
          end
          post '/something' do
            { id: 1, name: params[:name] }
          end

          add_swagger_documentation(openapi_version: '3.1')
        end
      end
    end

    def app
      TheApi::OAS31Api
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'returns openapi 3.1 format' do
      expect(subject['openapi']).to eq '3.1.0'
      expect(subject).not_to have_key('swagger')
    end

    it 'has components section' do
      expect(subject).to have_key('components')
    end
  end
end
