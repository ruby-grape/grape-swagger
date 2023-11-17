# frozen_string_literal: true

require 'spec_helper'

describe 'a hide mounted api' do
  before :all do
    class HideMountedApi < Grape::API
      desc 'Show this endpoint'
      get '/simple' do
        { foo: 'bar' }
      end

      desc 'Hide this endpoint', hidden: true
      get '/hide' do
        { foo: 'bar' }
      end

      desc 'Hide this endpoint using route setting'
      route_setting :swagger, hidden: true
      get '/hide_as_well' do
        { foo: 'bar' }
      end

      desc 'Lazily show endpoint', hidden: -> { false }
      get '/lazy' do
        { foo: 'bar' }
      end
    end

    class HideApi < Grape::API
      mount HideMountedApi
      add_swagger_documentation openapi_version: '3.0'
    end
  end

  def app
    HideApi
  end

  subject do
    get '/swagger_doc.json'
    puts last_response.body
    JSON.parse(last_response.body)
  end

  it "retrieves swagger-documentation that doesn't include hidden endpoints" do
    expect(subject).to eq(
      'info' => { 'title' => 'API title', 'version' => '0.0.1' },
      'openapi' => '3.0.0',
      'servers' => [{ 'url' => 'http://example.org' }],
      'tags' => [
        { 'name' => 'simple', 'description' => 'Operations about simples' },
        { 'name' => 'lazy', 'description' => 'Operations about lazies' }
      ],
      'paths' => {
        '/lazy' => {
          'get' => {
            'description' => 'Lazily show endpoint',
            'operationId' => 'getLazy',
            'responses' => { '200' => {
              'content' => { 'application/json' => {} },
              'description' => 'Lazily show endpoint'
            } },
            'tags' => ['lazy']
          }
        },
        '/simple' => {
          'get' => {
            'description' => 'Show this endpoint',
            'operationId' => 'getSimple',
            'responses' => {
              '200' => {
                'content' => { 'application/json' => {} },
                'description' => 'Show this endpoint'
              }
            },
            'tags' => ['simple']
          }
        }
      }
    )
  end
end

describe 'a hide mounted api with same namespace' do
  before :all do
    class HideNamespaceMountedApi < Grape::API
      desc 'Show this endpoint'
      get '/simple/show' do
        { foo: 'bar' }
      end

      desc 'Hide this endpoint', hidden: true
      get '/simple/hide' do
        { foo: 'bar' }
      end

      desc 'Lazily hide endpoint', hidden: -> { true }
      get '/simple/lazy' do
        { foo: 'bar' }
      end
    end

    class HideNamespaceApi < Grape::API
      mount HideNamespaceMountedApi
      add_swagger_documentation openapi_version: '3.0'
    end
  end

  def app
    HideNamespaceApi
  end

  it 'retrieves swagger-documentation on /swagger_doc' do
    get '/swagger_doc.json'
    expect(JSON.parse(last_response.body)).to eq(
      'info' => { 'title' => 'API title', 'version' => '0.0.1' },
      'openapi' => '3.0.0',
      'servers' => [{ 'url' => 'http://example.org' }],
      'tags' => [{ 'name' => 'simple', 'description' => 'Operations about simples' }],
      'paths' => {
        '/simple/show' => {
          'get' => {
            'description' => 'Show this endpoint',
            'operationId' => 'getSimpleShow',
            'responses' => {
              '200' => {
                'content' => { 'application/json' => {} },
                'description' => 'Show this endpoint'
              }
            },
            'tags' => ['simple']
          }
        }
      }
    )
  end

  it "retrieves the documentation for mounted-api that doesn't include hidden endpoints" do
    get '/swagger_doc/simple.json'
    expect(JSON.parse(last_response.body)).to eq(
      'info' => { 'title' => 'API title', 'version' => '0.0.1' },
      'openapi' => '3.0.0',
      'servers' => [{ 'url' => 'http://example.org' }],
      'tags' => [{ 'name' => 'simple', 'description' => 'Operations about simples' }],
      'paths' => {
        '/simple/show' => {
          'get' => {
            'description' => 'Show this endpoint',
            'operationId' => 'getSimpleShow',
            'responses' => {
              '200' => {
                'content' => { 'application/json' => {} },
                'description' => 'Show this endpoint'
              }
            },
            'tags' => ['simple']
          }
        }
      }
    )
  end
end
