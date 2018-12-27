# frozen_string_literal: true

require 'spec_helper'

describe 'global configuration stuff' do
  before :all do
    module TheApi
      class ConfigurationApi < Grape::API
        format :json
        version 'v3', using: :path

        desc 'This returns something',
             failure: [{ code: 400, message: 'NotFound' }]
        params do
          requires :foo, type: Integer
        end
        get :configuration do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation openapi_version: '3.0',
                                  format: :json,
                                  doc_version: '23',
                                  schemes: 'https',
                                  host: -> { 'another.host.com' },
                                  base_path: -> { '/somewhere/over/the/rainbow' },
                                  mount_path: 'documentation',
                                  add_base_path: true,
                                  add_version: true,
                                  security_definitions: { foo: { type: 'apiKey', in: 'header', name: 'bar' } },
                                  security: [{ api_key: [] }]
      end
    end
  end

  def app
    TheApi::ConfigurationApi
  end

  describe 'shows documentation paths' do
    subject do
      get '/v3/documentation'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['info']['version']).to eql '23'
      expect(subject['servers'].first['url']).to eql 'http://another.host.com/somewhere/over/the/rainbow'
      expect(subject['paths'].keys.first).to eql '/somewhere/over/the/rainbow/v3/configuration'
      expect(subject['components']['securitySchemes'].keys).to include('foo')
      expect(subject['components']['securitySchemes']['foo']).to include('name' => 'bar')
      expect(subject['security']).to include('api_key' => [])
    end
  end
end
