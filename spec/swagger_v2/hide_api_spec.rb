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

      desc 'Lazily show endpoint', hidden: -> { false }
      get '/lazy' do
        { foo: 'bar' }
      end
    end

    class HideApi < Grape::API
      mount HideMountedApi
      add_swagger_documentation
    end
  end

  def app
    HideApi
  end

  subject do
    get '/swagger_doc.json'
    JSON.parse(last_response.body)
  end

  it "retrieves swagger-documentation that doesn't include hidden endpoints" do
    expect(subject).to eq(
      'info' => { 'title' => 'API title', 'version' => '0.0.1' },
      'swagger' => '2.0',
      'produces' => ['application/xml', 'application/json', 'application/octet-stream', 'text/plain'],
      'host' => 'example.org',
      'tags' => [{ 'name' => 'simple', 'description' => 'Operations about simples' }, { 'name' => 'lazy', 'description' => 'Operations about lazies' }],
      'paths' => {
        '/simple' => {
          'get' => {
            'summary' => 'Show this endpoint',
            'description' => 'Show this endpoint',
            'produces' => ['application/json'],
            'tags' => ['simple'],
            'operationId' => 'getSimple',
            'responses' => { '200' => { 'description' => 'Show this endpoint' } }
          }
        },
        '/lazy' => {
          'get' => {
            'summary' => 'Lazily show endpoint',
            'description' => 'Lazily show endpoint',
            'produces' => ['application/json'],
            'tags' => ['lazy'],
            'operationId' => 'getLazy',
            'responses' => { '200' => { 'description' => 'Lazily show endpoint' } }
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
      add_swagger_documentation
    end
  end

  def app
    HideNamespaceApi
  end

  it 'retrieves swagger-documentation on /swagger_doc' do
    get '/swagger_doc.json'
    expect(JSON.parse(last_response.body)).to eq(
      'info' => { 'title' => 'API title', 'version' => '0.0.1' },
      'swagger' => '2.0',
      'produces' => ['application/xml', 'application/json', 'application/octet-stream', 'text/plain'],
      'host' => 'example.org',
      'tags' => [{ 'name' => 'simple', 'description' => 'Operations about simples' }],
      'paths' => {
        '/simple/show' => {
          'get' => {
            'summary' => 'Show this endpoint',
            'description' => 'Show this endpoint',
            'produces' => ['application/json'],
            'operationId' => 'getSimpleShow',
            'tags' => ['simple'], 'responses' => { '200' => { 'description' => 'Show this endpoint' } }
          }
        }
      }
    )
  end

  it "retrieves the documentation for mounted-api that doesn't include hidden endpoints" do
    get '/swagger_doc/simple.json'
    expect(JSON.parse(last_response.body)).to eq(
      'info' => { 'title' => 'API title', 'version' => '0.0.1' },
      'swagger' => '2.0',
      'produces' => ['application/xml', 'application/json', 'application/octet-stream', 'text/plain'],
      'host' => 'example.org',
      'tags' => [{ 'name' => 'simple', 'description' => 'Operations about simples' }],
      'paths' => {
        '/simple/show' => {
          'get' => {
            'summary' => 'Show this endpoint',
            'description' => 'Show this endpoint',
            'produces' => ['application/json'],
            'tags' => ['simple'],
            'operationId' => 'getSimpleShow',
            'responses' => { '200' => { 'description' => 'Show this endpoint' } }
          }
        }
      }
    )
  end
end
