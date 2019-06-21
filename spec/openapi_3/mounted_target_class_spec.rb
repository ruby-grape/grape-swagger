# frozen_string_literal: true

require 'spec_helper'

describe 'docs mounted separately from api' do
  before :all do
    class ActualApi < Grape::API
      desc 'Document root'

      desc 'This gets something.',
           notes: '_test_'
      get '/simple' do
        { bla: 'something' }
      end
    end

    class MountedDocs < Grape::API
      add_swagger_documentation target_class: ActualApi, openapi_version: '3.0'
    end

    class WholeApp < Grape::API
      mount ActualApi
      mount MountedDocs
    end
  end

  def app
    WholeApp
  end

  subject do
    JSON.parse(last_response.body)
  end

  it 'retrieves docs for actual api class' do
    get '/swagger_doc.json'
    expect(subject).to eq(
      'info' => { 'title' => 'API title', 'version' => '0.0.1' },
      'openapi' => '3.0.0',
      'servers' => [{ 'url' => 'http://example.org' }],
      'tags' => [{ 'name' => 'simple', 'description' => 'Operations about simples' }],
      'paths' => {
        '/simple' => {
          'get' => {
            'description' => 'This gets something.',
            'operationId' => 'getSimple',
            'responses' => {
              '200' => {
                'content' => { 'application/json' => {} },
                'description' => 'This gets something.'
              }
            },
            'tags' => ['simple']
          }
        }
      }
    )
  end

  it 'retrieves docs for endpoint in actual api class' do
    get '/swagger_doc/simple.json'
    expect(subject).to eq(
      'info' => { 'title' => 'API title', 'version' => '0.0.1' },
      'openapi' => '3.0.0',
      'servers' => [{ 'url' => 'http://example.org' }],
      'tags' => [{ 'name' => 'simple', 'description' => 'Operations about simples' }],
      'paths' => {
        '/simple' => {
          'get' => {
            'description' => 'This gets something.',
            'operationId' => 'getSimple',
            'responses' => {
              '200' => {
                'content' => { 'application/json' => {} },
                'description' => 'This gets something.'
              }
            },
            'tags' => ['simple']
          }
        }
      }
    )
  end
end
