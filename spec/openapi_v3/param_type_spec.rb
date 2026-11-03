# frozen_string_literal: true

require 'spec_helper'

describe 'param types (query, path, header) in OAS 3.0' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApiOAS3
      class ParamTypeApi < Grape::API
        # using `:param_type`
        desc 'full set of request param types',
             success: Entities::UseResponse
        params do
          optional :in_query, type: String, documentation: { param_type: 'query' }
          optional :in_header, type: String, documentation: { param_type: 'header' }
        end

        get '/defined_param_type' do
          { 'declared_params' => declared(params) }
        end

        desc 'full set of request param types with path param',
             success: Entities::UseResponse
        params do
          requires :in_path, type: Integer
          optional :in_query, type: String, documentation: { param_type: 'query' }
          optional :in_header, type: String, documentation: { param_type: 'header' }
        end

        get '/defined_param_type/:in_path' do
          { 'declared_params' => declared(params) }
        end

        desc 'delete with param types',
             success: Entities::UseResponse
        params do
          optional :in_path, type: Integer
          optional :in_query, type: String, documentation: { param_type: 'query' }
          optional :in_header, type: String, documentation: { param_type: 'header' }
        end

        delete '/defined_param_type/:in_path' do
          { 'declared_params' => declared(params) }
        end

        # using `:in`
        desc 'param types using `:in`',
             success: Entities::UseResponse
        params do
          optional :in_query, type: String, documentation: { in: 'query' }
          optional :in_header, type: String, documentation: { in: 'header' }
        end

        get '/defined_in' do
          { 'declared_params' => declared(params) }
        end

        desc 'param types using `:in` with path',
             success: Entities::UseResponse
        params do
          requires :in_path, type: Integer
          optional :in_query, type: String, documentation: { in: 'query' }
          optional :in_header, type: String, documentation: { in: 'header' }
        end

        get '/defined_in/:in_path' do
          { 'declared_params' => declared(params) }
        end

        desc 'delete with param types using `:in`'
        params do
          optional :in_path, type: Integer
          optional :in_query, type: String, documentation: { in: 'query' }
          optional :in_header, type: String, documentation: { in: 'header' }
        end

        delete '/defined_in/:in_path' do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation openapi_version: '3.0'
      end
    end
  end

  def app
    TheApiOAS3::ParamTypeApi
  end

  describe 'OAS3 format' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'returns openapi 3.0.3' do
      expect(subject['openapi']).to eq('3.0.3')
    end

    it 'has response with content wrapper for success' do
      response = subject['paths']['/defined_param_type/{in_path}']['delete']['responses']['200']
      expect(response['content']['application/json']['schema']['$ref']).to eq('#/components/schemas/UseResponse')
    end

    it 'has 204 response without content for delete without success model' do
      response = subject['paths']['/defined_in/{in_path}']['delete']['responses']['204']
      expect(response['description']).to eq('delete with param types using `:in`')
      expect(response['content']).to be_nil
    end
  end

  describe 'defined param types with :param_type' do
    subject do
      get '/swagger_doc/defined_param_type'
      JSON.parse(last_response.body)
    end

    it 'has query and header params with schema wrapper' do
      params = subject['paths']['/defined_param_type']['get']['parameters']

      query_param = params.find { |p| p['name'] == 'in_query' }
      expect(query_param['in']).to eq('query')
      expect(query_param['required']).to eq(false)
      expect(query_param['schema']).to eq({ 'type' => 'string' })

      header_param = params.find { |p| p['name'] == 'in_header' }
      expect(header_param['in']).to eq('header')
      expect(header_param['required']).to eq(false)
      expect(header_param['schema']).to eq({ 'type' => 'string' })
    end

    it 'has path param with schema wrapper' do
      params = subject['paths']['/defined_param_type/{in_path}']['get']['parameters']

      path_param = params.find { |p| p['name'] == 'in_path' }
      expect(path_param['in']).to eq('path')
      expect(path_param['required']).to eq(true)
      expect(path_param['schema']).to eq({ 'type' => 'integer', 'format' => 'int32' })
    end

    it 'has all three param types for path with params' do
      params = subject['paths']['/defined_param_type/{in_path}']['get']['parameters']

      expect(params.length).to eq(3)
      expect(params.map { |p| p['in'] }).to contain_exactly('path', 'query', 'header')
    end

    it 'has params for delete operation' do
      params = subject['paths']['/defined_param_type/{in_path}']['delete']['parameters']

      expect(params.length).to eq(3)
      path_param = params.find { |p| p['in'] == 'path' }
      expect(path_param['schema']['type']).to eq('integer')
    end
  end

  describe 'defined param types with :in' do
    subject do
      get '/swagger_doc/defined_in'
      JSON.parse(last_response.body)
    end

    it 'has query and header params with schema wrapper' do
      params = subject['paths']['/defined_in']['get']['parameters']

      query_param = params.find { |p| p['name'] == 'in_query' }
      expect(query_param['in']).to eq('query')
      expect(query_param['schema']).to eq({ 'type' => 'string' })

      header_param = params.find { |p| p['name'] == 'in_header' }
      expect(header_param['in']).to eq('header')
      expect(header_param['schema']).to eq({ 'type' => 'string' })
    end

    it 'has path param with integer schema' do
      params = subject['paths']['/defined_in/{in_path}']['get']['parameters']

      path_param = params.find { |p| p['name'] == 'in_path' }
      expect(path_param['in']).to eq('path')
      expect(path_param['required']).to eq(true)
      expect(path_param['schema']['type']).to eq('integer')
    end

    it 'has all params for delete' do
      params = subject['paths']['/defined_in/{in_path}']['delete']['parameters']

      expect(params.length).to eq(3)
    end
  end
end
