# frozen_string_literal: true

require 'spec_helper'

describe 'OAS 3.0 requestBody from param_type: body' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module ParamTypeBodyTest
      class BodyParamTypeApi < Grape::API
        namespace :wo_entities do
          desc 'post in body /wo entity'
          params do
            requires :in_body_1, type: Integer, documentation: { desc: 'in_body_1', param_type: 'body' }
            optional :in_body_2, type: String, documentation: { desc: 'in_body_2', param_type: 'body' }
            optional :in_body_3, type: String, documentation: { desc: 'in_body_3', param_type: 'body' }
          end

          post '/in_body' do
            { 'declared_params' => declared(params) }
          end

          desc 'put in body /wo entity'
          params do
            requires :key, type: Integer
            optional :in_body_1, type: Integer, documentation: { desc: 'in_body_1', param_type: 'body' }
            optional :in_body_2, type: String, documentation: { desc: 'in_body_2', param_type: 'body' }
            optional :in_body_3, type: String, documentation: { desc: 'in_body_3', param_type: 'body' }
          end

          put '/in_body/:key' do
            { 'declared_params' => declared(params) }
          end
        end

        namespace :with_entities do
          desc 'post in body with entity',
               success: ::Entities::ResponseItem
          params do
            requires :name, type: String, documentation: { desc: 'name', param_type: 'body' }
          end

          post '/in_body' do
            { 'declared_params' => declared(params) }
          end

          desc 'put in body with entity',
               success: ::Entities::ResponseItem
          params do
            requires :id, type: Integer
            optional :name, type: String, documentation: { desc: 'name', param_type: 'body' }
          end

          put '/in_body/:id' do
            { 'declared_params' => declared(params) }
          end
        end

        namespace :with_entity_param do
          desc 'post in body with entity parameter'
          params do
            optional :data, type: ::Entities::NestedModule::ApiResponse, documentation: { desc: 'request data' }
          end

          post do
            { 'declared_params' => declared(params) }
          end
        end

        add_swagger_documentation openapi_version: '3.0'
      end
    end
  end

  def app
    ParamTypeBodyTest::BodyParamTypeApi
  end

  describe 'no entity given' do
    subject do
      get '/swagger_doc/wo_entities'
      JSON.parse(last_response.body)
    end

    describe 'POST /wo_entities/in_body' do
      it 'has requestBody with schema reference' do
        request_body = subject['paths']['/wo_entities/in_body']['post']['requestBody']
        expect(request_body['content']['application/json']['schema']).to have_key('$ref')
      end

      it 'creates schema with all body parameters' do
        # Find the schema for POST body
        schemas = subject['components']['schemas']
        post_schema = schemas.find { |name, _| name.include?('post') && name.include?('WoEntities') }&.last

        expect(post_schema).to be_present
        expect(post_schema['type']).to eq('object')
        expect(post_schema['properties']).to have_key('in_body_1')
        expect(post_schema['properties']).to have_key('in_body_2')
        expect(post_schema['properties']).to have_key('in_body_3')
      end

      it 'marks required fields' do
        schemas = subject['components']['schemas']
        post_schema = schemas.find { |name, _| name.include?('post') && name.include?('WoEntities') }&.last

        expect(post_schema['required']).to include('in_body_1')
      end

      it 'has correct types for body parameters' do
        schemas = subject['components']['schemas']
        post_schema = schemas.find { |name, _| name.include?('post') && name.include?('WoEntities') }&.last

        expect(post_schema['properties']['in_body_1']['type']).to eq('integer')
        expect(post_schema['properties']['in_body_2']['type']).to eq('string')
      end
    end

    describe 'PUT /wo_entities/in_body/{key}' do
      it 'has path parameter for :key' do
        params = subject['paths']['/wo_entities/in_body/{key}']['put']['parameters']
        key_param = params.find { |p| p['name'] == 'key' }

        expect(key_param['in']).to eq('path')
        expect(key_param['required']).to be true
        expect(key_param['schema']['type']).to eq('integer')
      end

      it 'has requestBody with remaining body params' do
        request_body = subject['paths']['/wo_entities/in_body/{key}']['put']['requestBody']
        expect(request_body['content']['application/json']['schema']).to have_key('$ref')
      end

      it 'does not include path param in body schema' do
        schemas = subject['components']['schemas']
        put_schema = schemas.find { |name, _| name.include?('put') && name.include?('WoEntities') }&.last

        expect(put_schema['properties']).not_to have_key('key')
        expect(put_schema['properties']).to have_key('in_body_1')
      end
    end
  end

  describe 'entity given' do
    subject do
      get '/swagger_doc/with_entities'
      JSON.parse(last_response.body)
    end

    describe 'POST /with_entities/in_body' do
      it 'has requestBody with schema reference' do
        request_body = subject['paths']['/with_entities/in_body']['post']['requestBody']
        expect(request_body['content']['application/json']['schema']).to have_key('$ref')
      end

      it 'creates schema with body parameters' do
        schemas = subject['components']['schemas']
        post_schema = schemas.find { |name, _| name.include?('post') && name.include?('WithEntities') }&.last

        expect(post_schema['type']).to eq('object')
        expect(post_schema['properties']['name']['type']).to eq('string')
        expect(post_schema['required']).to include('name')
      end
    end

    describe 'PUT /with_entities/in_body/{id}' do
      it 'has path parameter' do
        params = subject['paths']['/with_entities/in_body/{id}']['put']['parameters']
        id_param = params.find { |p| p['name'] == 'id' }

        expect(id_param['in']).to eq('path')
        expect(id_param['required']).to be true
        expect(id_param['schema']['type']).to eq('integer')
      end

      it 'has requestBody with body params' do
        request_body = subject['paths']['/with_entities/in_body/{id}']['put']['requestBody']
        expect(request_body['content']['application/json']['schema']).to have_key('$ref')
      end
    end
  end

  describe 'complex entity given' do
    subject do
      get '/swagger_doc/with_entity_param'
      JSON.parse(last_response.body)
    end

    it 'has requestBody with schema reference' do
      request_body = subject['paths']['/with_entity_param']['post']['requestBody']
      expect(request_body['content']['application/json']['schema']).to have_key('$ref')
    end

    it 'includes nested entity in components schemas' do
      schemas = subject['components']['schemas']
      nested_schema = schemas.find { |name, _| name.include?('NestedModule') || name.include?('ApiResponse') }
      expect(nested_schema).to be_present
    end

    it 'has body schema with data property' do
      schemas = subject['components']['schemas']
      post_schema = schemas.find { |name, _| name.include?('post') && name.include?('WithEntityParam') }&.last

      expect(post_schema['type']).to eq('object')
      expect(post_schema['properties']).to have_key('data')
      expect(post_schema['properties']['data']['description']).to eq('request data')
    end
  end
end
