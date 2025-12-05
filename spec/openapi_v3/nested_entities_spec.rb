# frozen_string_literal: true

require 'spec_helper'

describe 'Nested entities in OpenAPI 3.0' do
  before :all do
    module NestedEntitiesOAS3
      module Entities
        class ResponseItem < Grape::Entity
          expose :id, documentation: { type: Integer, desc: 'Item ID', required: true }
          expose :name, documentation: { type: String, desc: 'Item name', required: true }
        end

        class UseResponse < Grape::Entity
          expose :description, documentation: { type: String, desc: 'Description', required: true }
          expose :items, documentation: { type: ResponseItem, is_array: true, desc: 'Items', required: true }
        end

        class ThirdLevel < Grape::Entity
          expose :text, documentation: { type: String, desc: 'Text', required: true }
        end

        class SecondLevel < Grape::Entity
          expose :parts, documentation: { type: ThirdLevel, desc: 'Parts', required: true }
        end

        class FirstLevel < Grape::Entity
          expose :parts, documentation: { type: SecondLevel, desc: 'Parts', required: true }
        end
      end

      class API < Grape::API
        format :json

        desc 'Get nested response',
             success: Entities::UseResponse
        get '/nested' do
          { description: 'test', items: [{ id: 1, name: 'item' }] }
        end

        desc 'Get deeply nested response',
             success: Entities::FirstLevel
        get '/deep_nested' do
          { parts: { parts: { parts: { text: 'deep' } } } }
        end

        add_swagger_documentation(openapi_version: '3.0')
      end
    end
  end

  def app
    NestedEntitiesOAS3::API
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'schema references' do
    it 'uses components/schemas path for refs' do
      json_string = subject.to_json
      expect(json_string).to include('#/components/schemas/')
      expect(json_string).not_to include('#/definitions/')
    end

    it 'places entity schemas in components/schemas' do
      schemas = subject['components']['schemas']
      # Schema names may include module path
      expect(schemas.keys.any? { |k| k.include?('UseResponse') }).to be true
    end

    it 'places response entity schemas in components/schemas' do
      schemas = subject['components']['schemas']
      expect(schemas.keys.any? { |k| k.include?('FirstLevel') }).to be true
    end
  end

  describe 'response schema reference' do
    let(:nested_response) { subject['paths']['/nested']['get']['responses']['200'] }

    it 'references schema in content' do
      content = nested_response['content']['application/json']
      expect(content['schema']['$ref']).to match(%r{#/components/schemas/.*UseResponse})
    end
  end

  describe 'deeply nested response' do
    let(:deep_response) { subject['paths']['/deep_nested']['get']['responses']['200'] }

    it 'references first level schema in response' do
      content = deep_response['content']['application/json']
      expect(content['schema']['$ref']).to match(%r{#/components/schemas/.*FirstLevel})
    end
  end
end

describe 'Reference path conversion' do
  it 'converts definitions refs to components/schemas refs' do
    schema = GrapeSwagger::OpenAPI::Schema.new
    schema.canonical_name = 'TestModel'

    spec = GrapeSwagger::OpenAPI::Document.new
    spec.components.add_schema('TestModel', schema)

    exporter = GrapeSwagger::Exporter::OAS30.new(spec)
    output = exporter.export

    # The schema should export as a reference
    exported_schema = output[:components][:schemas]['TestModel']
    expect(exported_schema).to eq({ '$ref' => '#/components/schemas/TestModel' })
  end

  it 'converts inline refs in hash schemas' do
    spec = GrapeSwagger::OpenAPI::Document.new
    exporter = GrapeSwagger::Exporter::OAS30.new(spec)

    # Simulate a hash with Swagger 2.0 style ref
    hash_schema = { '$ref' => '#/definitions/SomeModel' }
    result = exporter.send(:export_hash_schema, hash_schema)

    expect(result['$ref']).to eq('#/components/schemas/SomeModel')
  end
end
