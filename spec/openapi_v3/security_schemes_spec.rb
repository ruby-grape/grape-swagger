# frozen_string_literal: true

require 'spec_helper'

describe 'Security schemes in OpenAPI 3.0' do
  before :all do
    module TheApi
      class SecurityOAS3Api < Grape::API
        format :json

        desc 'Protected endpoint', security: [{ api_key: [] }]
        get '/protected' do
          { secret: 'data' }
        end

        desc 'OAuth protected', security: [{ oauth2: ['read:users', 'write:users'] }]
        get '/oauth_protected' do
          { user: 'data' }
        end

        desc 'Public endpoint', security: []
        get '/public' do
          { public: 'data' }
        end

        add_swagger_documentation(
          openapi_version: '3.0',
          security_definitions: {
            api_key: {
              type: 'apiKey',
              name: 'X-API-Key',
              in: 'header',
              description: 'API Key authentication'
            },
            basic_auth: {
              type: 'basic',
              description: 'Basic HTTP authentication'
            },
            oauth2: {
              type: 'oauth2',
              flow: 'accessCode',
              authorizationUrl: 'https://example.com/oauth/authorize',
              tokenUrl: 'https://example.com/oauth/token',
              scopes: {
                'read:users': 'Read user data',
                'write:users': 'Modify user data'
              }
            }
          },
          security: [{ api_key: [] }]
        )
      end
    end
  end

  def app
    TheApi::SecurityOAS3Api
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'security schemes location' do
    it 'places security schemes under components' do
      expect(subject['components']).to have_key('securitySchemes')
    end

    it 'does not have securityDefinitions at root level' do
      expect(subject).not_to have_key('securityDefinitions')
    end
  end

  describe 'apiKey security scheme' do
    let(:api_key_scheme) { subject['components']['securitySchemes']['api_key'] }

    it 'preserves apiKey type' do
      expect(api_key_scheme['type']).to eq('apiKey')
    end

    it 'includes name and location' do
      expect(api_key_scheme['name']).to eq('X-API-Key')
      expect(api_key_scheme['in']).to eq('header')
    end

    it 'includes description' do
      expect(api_key_scheme['description']).to eq('API Key authentication')
    end
  end

  describe 'basic auth conversion' do
    let(:basic_scheme) { subject['components']['securitySchemes']['basic_auth'] }

    it 'converts basic to http type' do
      expect(basic_scheme['type']).to eq('http')
    end

    it 'sets scheme to basic' do
      expect(basic_scheme['scheme']).to eq('basic')
    end
  end

  describe 'OAuth2 security scheme' do
    let(:oauth_scheme) { subject['components']['securitySchemes']['oauth2'] }

    it 'preserves oauth2 type' do
      expect(oauth_scheme['type']).to eq('oauth2')
    end

    it 'converts flow to OAS3 flows format' do
      expect(oauth_scheme).to have_key('flows')
    end

    it 'maps accessCode flow to authorizationCode' do
      expect(oauth_scheme['flows']).to have_key('authorizationCode')
    end

    it 'includes authorization and token URLs' do
      flow = oauth_scheme['flows']['authorizationCode']
      expect(flow['authorizationUrl']).to eq('https://example.com/oauth/authorize')
      expect(flow['tokenUrl']).to eq('https://example.com/oauth/token')
    end

    it 'includes scopes' do
      flow = oauth_scheme['flows']['authorizationCode']
      expect(flow['scopes']).to include('read:users' => 'Read user data')
    end
  end

  describe 'operation-level security' do
    it 'applies security to protected endpoint' do
      security = subject['paths']['/protected']['get']['security']
      expect(security).to eq([{ 'api_key' => [] }])
    end

    it 'applies OAuth security with scopes' do
      security = subject['paths']['/oauth_protected']['get']['security']
      expect(security).to eq([{ 'oauth2' => ['read:users', 'write:users'] }])
    end

    it 'allows empty security for public endpoints' do
      security = subject['paths']['/public']['get']['security']
      expect(security).to eq([])
    end
  end

  describe 'global security' do
    it 'applies global security requirement' do
      expect(subject['security']).to eq([{ 'api_key' => [] }])
    end
  end
end
