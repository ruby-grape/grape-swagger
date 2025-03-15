# frozen_string_literal: true

require 'spec_helper'

describe 'components in OpenAPI 3.0' do
  include_context "#{MODEL_PARSER} swagger example"

  def app
    Class.new(Grape::API) do
      format :json

      desc 'Get something',
           success: Entities::Something
      get '/something' do
        something = OpenStruct.new text: 'something'
        present something, with: Entities::Something
      end

      add_swagger_documentation security_definitions: {
        api_key: {
          type: 'apiKey',
          name: 'api_key',
          in: 'header'
        },
        oauth2: {
          type: 'oauth2',
          flows: {
            implicit: {
              authorizationUrl: 'https://example.com/oauth/authorize',
              scopes: {
                'read:items' => 'Read items',
                'write:items' => 'Write items'
              }
            }
          }
        }
      }
    end
  end

  describe 'components object' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'has components object' do
      expect(subject).to have_key('components')
      expect(subject['components']).to be_a(Hash)
    end

    it 'has schemas in components' do
      expect(subject['components']).to have_key('schemas')
      expect(subject['components']['schemas']).to be_a(Hash)
      expect(subject['components']['schemas']).to have_key('Something')
    end

    it 'has securitySchemes in components' do
      expect(subject['components']).to have_key('securitySchemes')
      expect(subject['components']['securitySchemes']).to be_a(Hash)
    end

    it 'has api_key security scheme' do
      expect(subject['components']['securitySchemes']).to have_key('api_key')
      api_key = subject['components']['securitySchemes']['api_key']
      expect(api_key['type']).to eq('apiKey')
      expect(api_key['name']).to eq('api_key')
      expect(api_key['in']).to eq('header')
    end

    it 'has oauth2 security scheme' do
      expect(subject['components']['securitySchemes']).to have_key('oauth2')
      oauth2 = subject['components']['securitySchemes']['oauth2']
      expect(oauth2['type']).to eq('oauth2')
      expect(oauth2).to have_key('flows')
      expect(oauth2['flows']).to have_key('implicit')
    end
  end
end 