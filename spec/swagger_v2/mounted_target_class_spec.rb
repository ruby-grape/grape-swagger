# frozen_string_literal: true

require 'spec_helper'

xdescribe 'docs mounted separately from api' do
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
      add_swagger_documentation(target_class: ActualApi)
    end

    class WholeApp < Grape::API
      mount ActualApi
      mount MountedDocs
    end
  end

  def app
    WholeApp
  end

  it 'retrieves docs for actual api class' do
    get '/swagger_doc.json'
    expect(JSON.parse(last_response.body)).to eq(
      'info' => { 'title' => 'API title', 'version' => '0.0.1' },
      'swagger' => '2.0',
      'produces' => ['application/xml', 'application/json', 'application/octet-stream', 'text/plain'],
      'host' => 'example.org',
      'tags' => [{ 'name' => 'simple', 'description' => 'Operations about simples' }],
      'paths' => {
        '/simple' => {
          'get' => {
            'description' => 'This gets something.',
            'produces' => ['application/json'],
            'responses' => { '200' => { 'description' => 'This gets something.' } },
            'tags' => ['simple'],
            'operationId' => 'getSimple'
          }
        }
      }
    )
  end

  it 'retrieves docs for endpoint in actual api class' do
    get '/swagger_doc/simple.json'
    expect(JSON.parse(last_response.body)).to eq(
      'info' => { 'title' => 'API title', 'version' => '0.0.1' },
      'swagger' => '2.0',
      'tags' => [{ 'name' => 'simple', 'description' => 'Operations about simples' }],
      'produces' => ['application/xml', 'application/json', 'application/octet-stream', 'text/plain'],
      'host' => 'example.org',
      'paths' => {
        '/simple' => {
          'get' => {
            'description' => 'This gets something.',
            'produces' => ['application/json'],
            'responses' => {
              '200' => { 'description' => 'This gets something.' }
            },
            'tags' => ['simple'],
            'operationId' => 'getSimple'
          }
        }
      }
    )
  end
end
