# frozen_string_literal: true

require 'spec_helper'

describe 'nullable extension in Swagger 2.0' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :items do
        params do
          optional :nickname, type: String, documentation: { nullable: true }
          optional :regular_field, type: String
        end
        post do
          { message: 'created' }
        end

        params do
          optional :search, type: String, documentation: { nullable: true }
        end
        get do
          []
        end
      end

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'body parameters (POST)' do
    it 'uses x-nullable extension in definition schema' do
      definition = subject['definitions']['postItems']
      props = definition['properties']

      expect(props['nickname']['x-nullable']).to eq(true)
      expect(props['nickname']).not_to have_key('nullable')
      expect(props['regular_field']).not_to have_key('x-nullable')
      expect(props['regular_field']).not_to have_key('nullable')
    end
  end

  describe 'query parameters (GET)' do
    it 'uses x-nullable extension for query params' do
      params = subject['paths']['/items']['get']['parameters']
      nullable_param = params.find { |p| p['name'] == 'search' }

      expect(nullable_param['x-nullable']).to eq(true)
      expect(nullable_param).not_to have_key('nullable')
    end
  end
end
