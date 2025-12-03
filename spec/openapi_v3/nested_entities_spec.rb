# frozen_string_literal: true

require 'spec_helper'

describe 'Nested entities in OpenAPI 3.0' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class NestedEntitiesOAS3Api < Grape::API
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
    TheApi::NestedEntitiesOAS3Api
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
      expect(subject['components']['schemas']).to have_key('UseResponse')
    end

    it 'places response entity schemas in components/schemas' do
      expect(subject['components']['schemas']).to have_key('FirstLevel')
    end
  end

  describe 'response schema reference' do
    let(:nested_response) { subject['paths']['/nested']['get']['responses']['200'] }

    it 'references schema in content' do
      content = nested_response['content']['application/json']
      expect(content['schema']['$ref']).to eq('#/components/schemas/UseResponse')
    end
  end

  describe 'deeply nested response' do
    let(:deep_response) { subject['paths']['/deep_nested']['get']['responses']['200'] }

    it 'references first level schema in response' do
      content = deep_response['content']['application/json']
      expect(content['schema']['$ref']).to eq('#/components/schemas/FirstLevel')
    end
  end
end

describe 'Reference path conversion' do
  it 'converts definitions refs to components/schemas refs' do
    schema = GrapeSwagger::ApiModel::Schema.new
    schema.canonical_name = 'TestModel'

    spec = GrapeSwagger::ApiModel::Spec.new
    spec.components.add_schema('TestModel', schema)

    exporter = GrapeSwagger::Exporter::OAS30.new(spec)
    output = exporter.export

    # The schema should export as a reference
    exported_schema = output[:components][:schemas]['TestModel']
    expect(exported_schema).to eq({ '$ref' => '#/components/schemas/TestModel' })
  end

  it 'converts inline refs in hash schemas' do
    spec = GrapeSwagger::ApiModel::Spec.new
    exporter = GrapeSwagger::Exporter::OAS30.new(spec)

    # Simulate a hash with Swagger 2.0 style ref
    hash_schema = { '$ref' => '#/definitions/SomeModel' }
    result = exporter.send(:export_hash_schema, hash_schema)

    expect(result['$ref']).to eq('#/components/schemas/SomeModel')
  end
end
