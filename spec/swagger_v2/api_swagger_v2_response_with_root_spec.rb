# frozen_string_literal: true

require 'spec_helper'

describe 'response with root' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class ResponseApiWithRoot < Grape::API
        format :json

        desc 'This returns something',
             http_codes: [{ code: 200, model: Entities::Something }]
        get '/ordinary_response' do
          { 'declared_params' => declared(params) }
        end

        desc 'This returns something',
             is_array: true,
             http_codes: [{ code: 200, model: Entities::Something }]
        get '/response_with_array' do
          { 'declared_params' => declared(params) }
        end

        route_setting :swagger, root: true
        desc 'This returns something',
             http_codes: [{ code: 200, model: Entities::Something }]
        get '/response_with_root' do
          { 'declared_params' => declared(params) }
        end

        route_setting :swagger, root: true
        desc 'This returns underscored root',
             http_codes: [{ code: 200, model: Entities::ApiError }]
        get '/response_with_root_underscore' do
          { 'declared_params' => declared(params) }
        end

        route_setting :swagger, root: true
        desc 'This returns something',
             is_array: true,
             http_codes: [{ code: 200, model: Entities::Something }]
        get '/response_with_array_and_root' do
          { 'declared_params' => declared(params) }
        end

        route_setting :swagger, root: 'custom_root'
        desc 'This returns something',
             http_codes: [{ code: 200, model: Entities::Something }]
        get '/response_with_custom_root' do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::ResponseApiWithRoot
  end

  describe 'GET /ordinary_response' do
    subject do
      get '/swagger_doc/ordinary_response'
      JSON.parse(last_response.body)
    end

    it 'does not add root or array' do
      schema = subject.dig('paths', '/ordinary_response', 'get', 'responses', '200', 'schema')
      expect(schema).to eq(
        '$ref' => '#/definitions/Something'
      )
    end
  end

  describe 'GET /response_with_array' do
    subject do
      get '/swagger_doc/response_with_array'
      JSON.parse(last_response.body)
    end

    it 'adds array to the response' do
      schema = subject.dig('paths', '/response_with_array', 'get', 'responses', '200', 'schema')
      expect(schema).to eq(
        'type' => 'array', 'items' => { '$ref' => '#/definitions/Something' }
      )
    end
  end

  describe 'GET /response_with_root' do
    subject do
      get '/swagger_doc/response_with_root'
      JSON.parse(last_response.body)
    end

    it 'adds root to the response' do
      schema = subject.dig('paths', '/response_with_root', 'get', 'responses', '200', 'schema')
      expect(schema).to eq(
        'type' => 'object',
        'properties' => { 'something' => { '$ref' => '#/definitions/Something' } }
      )
    end
  end

  describe 'GET /response_with_root_underscore' do
    subject do
      get '/swagger_doc/response_with_root_underscore'
      JSON.parse(last_response.body)
    end

    it 'adds root to the response' do
      schema = subject.dig('paths', '/response_with_root_underscore', 'get', 'responses', '200', 'schema')
      expect(schema).to eq(
        'type' => 'object',
        'properties' => { 'api_error' => { '$ref' => '#/definitions/ApiError' } }
      )
    end
  end

  describe 'GET /response_with_array_and_root' do
    subject do
      get '/swagger_doc/response_with_array_and_root'
      JSON.parse(last_response.body)
    end

    it 'adds root and array to the response' do
      schema = subject.dig('paths', '/response_with_array_and_root', 'get', 'responses', '200', 'schema')
      expect(schema).to eq(
        'type' => 'object',
        'properties' => {
          'somethings' => { 'type' => 'array', 'items' => { '$ref' => '#/definitions/Something' } }
        }
      )
    end
  end

  describe 'GET /response_with_custom_root' do
    subject do
      get '/swagger_doc/response_with_custom_root'
      JSON.parse(last_response.body)
    end

    it 'adds root to the response' do
      schema = subject.dig('paths', '/response_with_custom_root', 'get', 'responses', '200', 'schema')
      expect(schema).to eq(
        'type' => 'object',
        'properties' => { 'custom_root' => { '$ref' => '#/definitions/Something' } }
      )
    end
  end
end
