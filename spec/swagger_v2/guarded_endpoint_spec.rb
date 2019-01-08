# frozen_string_literal: true

require 'spec_helper'

class SampleAuth < Grape::Middleware::Base
  module AuthMethods
    attr_accessor :access_token

    def protected_endpoint=(protected)
      @protected_endpoint = protected
    end

    def protected_endpoint?
      @protected_endpoint || false
    end

    def resource_owner
      @resource_owner = true if access_token == '12345'
    end
  end

  def context
    env['api.endpoint']
  end

  def before
    context.extend(SampleAuth::AuthMethods)
    context.protected_endpoint = context.options[:route_options][:auth].present?

    return unless context.protected_endpoint?

    scopes = context.options[:route_options][:auth][:scopes]
    authorize!(*scopes) unless scopes.include? false
    context.access_token = env['HTTP_AUTHORIZATION']
  end
end

module Extension
  def sample_auth(*scopes)
    description = route_setting(:description) || route_setting(:description, {})
    description[:auth] = { scopes: scopes }
  end

  GrapeInstance.extend self
end

describe 'a guarded api endpoint' do
  before :all do
    class GuardedMountedApi < Grape::API
      resource_owner_valid = proc { |token_owner = nil| token_owner.nil? }

      desc 'Show endpoint if authenticated'
      route_setting :swagger, hidden: resource_owner_valid
      get '/auth' do
        { foo: 'bar' }
      end
    end

    class GuardedApi < Grape::API
      mount GuardedMountedApi
      add_swagger_documentation endpoint_auth_wrapper: SampleAuth,
                                swagger_endpoint_guard: 'sample_auth false',
                                token_owner: 'resource_owner'
    end
  end

  def app
    GuardedApi
  end

  let(:endpoint) { '/swagger_doc.json' }
  let(:auth_token) { nil }

  subject do
    get endpoint, {}, 'HTTP_AUTHORIZATION' => auth_token
    JSON.parse(last_response.body)
  end

  context 'accessing the main doc endpoint' do
    let(:endpoint) { '/swagger_doc.json' }

    context 'when a correct token is passed with the request' do
      let(:auth_token) { '12345' }

      it 'retrieves swagger-documentation for the endpoint' do
        expect(subject).to eq(
          'info' => { 'title' => 'API title', 'version' => '0.0.1' },
          'swagger' => '2.0',
          'produces' => ['application/xml', 'application/json', 'application/octet-stream', 'text/plain'],
          'host' => 'example.org',
          'tags' => [{ 'name' => 'auth', 'description' => 'Operations about auths' }],
          'paths' => {
            '/auth' => {
              'get' => {
                'description' => 'Show endpoint if authenticated',
                'produces' => ['application/json'],
                'tags' => ['auth'],
                'operationId' => 'getAuth',
                'responses' => { '200' => { 'description' => 'Show endpoint if authenticated' } }
              }
            }
          }
        )
      end
    end

    context 'when a bad token is passed with the request' do
      let(:auth_token) { '123456' }

      it 'does not retrieve swagger-documentation for the endpoint - only the info_object' do
        expect(subject).to eq(
          'info' => { 'title' => 'API title', 'version' => '0.0.1' },
          'swagger' => '2.0',
          'produces' => ['application/xml', 'application/json', 'application/octet-stream', 'text/plain'],
          'host' => 'example.org'
        )
      end
    end
  end

  context 'accessing the tag specific endpoint' do
    let(:endpoint) { '/swagger_doc/auth.json' }

    context 'when a correct token is passed with the request' do
      let(:auth_token) { '12345' }

      it 'retrieves swagger-documentation for the endpoint' do
        expect(subject).to eq(
          'info' => { 'title' => 'API title', 'version' => '0.0.1' },
          'swagger' => '2.0',
          'produces' => ['application/xml', 'application/json', 'application/octet-stream', 'text/plain'],
          'host' => 'example.org',
          'tags' => [{ 'name' => 'auth', 'description' => 'Operations about auths' }],
          'paths' => {
            '/auth' => {
              'get' => {
                'description' => 'Show endpoint if authenticated',
                'produces' => ['application/json'],
                'tags' => ['auth'],
                'operationId' => 'getAuth',
                'responses' => { '200' => { 'description' => 'Show endpoint if authenticated' } }
              }
            }
          }
        )
      end
    end

    context 'when a bad token is passed with the request' do
      let(:auth_token) { '123456' }

      it 'does not retrieve swagger-documentation for the endpoint - only the info_object' do
        expect(subject).to eq(
          'info' => { 'title' => 'API title', 'version' => '0.0.1' },
          'swagger' => '2.0',
          'produces' => ['application/xml', 'application/json', 'application/octet-stream', 'text/plain'],
          'host' => 'example.org'
        )
      end
    end
  end
end
