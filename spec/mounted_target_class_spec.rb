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
      'apiVersion' => '0.1',
      'swaggerVersion' => '1.2',
      'info' => {},
      'produces' => Grape::ContentTypes::CONTENT_TYPES.values.uniq,
      'apis' => [
        { 'path' => '/simple.{format}', 'description' => 'Operations about simples' }
      ]
    )
  end

  it 'retrieves docs for endpoint in actual api class' do
    get '/swagger_doc/simple.json'
    expect(JSON.parse(last_response.body)).to eq(
      'apiVersion' => '0.1',
      'swaggerVersion' => '1.2',
      'basePath' => 'http://example.org',
      'resourcePath' => '/simple',
      'produces' => Grape::ContentTypes::CONTENT_TYPES.values.uniq,
      'apis' => [{
        'path' => '/simple.{format}',
        'operations' => [{
          'notes' => '_test_',
          'summary' => 'This gets something.',
          'nickname' => 'GET-simple---format-',
          'method' => 'GET',
          'parameters' => [],
          'type' => 'void'
        }]
      }]
    )
  end
end
