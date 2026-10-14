# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1 specific features' do
  before :all do
    module TheApi
      class OAS31FeaturesApi < Grape::API
        format :json

        desc 'Simple endpoint'
        get '/items' do
          []
        end

        add_swagger_documentation(openapi_version: '3.1')
      end
    end
  end

  def app
    TheApi::OAS31FeaturesApi
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'openapi version' do
    it 'uses 3.1.0 version string' do
      expect(subject['openapi']).to eq('3.1.0')
    end
  end

  describe 'nullable types' do
    before :all do
      module OAS31NullableApi
        module Entities
          class NullableItem < Grape::Entity
            expose :name, documentation: { type: String, desc: 'Name' }
            expose :description, documentation: { type: String, desc: 'Optional description', x: { nullable: true } }
          end
        end

        class API < Grape::API
          format :json

          desc 'Get nullable item',
               entity: Entities::NullableItem
          get '/nullable_item' do
            present OpenStruct.new(name: 'test'), with: Entities::NullableItem
          end

          add_swagger_documentation(openapi_version: '3.1')
        end
      end
    end

    def app
      OAS31NullableApi::API
    end

    it 'uses type array for nullable instead of nullable keyword' do
      get '/swagger_doc'
      json = JSON.parse(last_response.body)

      # OAS 3.1 should NOT use nullable keyword
      json_string = json.to_json
      expect(json_string).not_to include('"nullable":true')
      expect(json_string).not_to include('"nullable": true')
    end
  end

  describe 'license with identifier' do
    before :all do
      module OAS31LicenseApi
        class API < Grape::API
          format :json

          desc 'Simple endpoint'
          get '/test' do
            {}
          end

          add_swagger_documentation(
            openapi_version: '3.1',
            info: {
              license: {
                name: 'MIT',
                identifier: 'MIT'
              }
            }
          )
        end
      end
    end

    def app
      OAS31LicenseApi::API
    end

    it 'includes identifier in license' do
      get '/swagger_doc'
      json = JSON.parse(last_response.body)

      expect(json['info']['license']['name']).to eq('MIT')
      expect(json['info']['license']['identifier']).to eq('MIT')
    end

    it 'does not include url when identifier is present' do
      get '/swagger_doc'
      json = JSON.parse(last_response.body)

      expect(json['info']['license']).not_to have_key('url')
    end
  end
end

describe 'OpenAPI 3.1 webhooks' do
  describe 'manual webhook configuration' do
    it 'exports webhooks in OAS 3.1 format' do
      # Create API Model manually to test webhooks export
      spec = GrapeSwagger::OpenAPI::Document.new
      spec.info.title = 'Webhook Test API'
      spec.info.version = '1.0'

      # Create a webhook path item
      webhook_path = GrapeSwagger::OpenAPI::PathItem.new
      webhook_op = GrapeSwagger::OpenAPI::Operation.new
      webhook_op.summary = 'New pet notification'
      webhook_op.description = 'Receives notification when a new pet is added'

      request_body = GrapeSwagger::OpenAPI::RequestBody.new
      request_body.required = true
      schema = GrapeSwagger::OpenAPI::Schema.new(type: 'object')
      schema.add_property('petName', GrapeSwagger::OpenAPI::Schema.new(type: 'string'))
      request_body.add_media_type('application/json', schema: schema)
      webhook_op.request_body = request_body

      response = GrapeSwagger::OpenAPI::Response.new
      response.description = 'Webhook received successfully'
      webhook_op.add_response(200, response)

      webhook_path.add_operation(:post, webhook_op)
      spec.add_webhook('newPet', webhook_path)

      # Export as OAS 3.1
      exporter = GrapeSwagger::Exporter::OAS31.new(spec)
      output = exporter.export

      expect(output[:openapi]).to eq('3.1.0')
      expect(output[:webhooks]).to have_key('newPet')
      expect(output[:webhooks]['newPet'][:post][:summary]).to eq('New pet notification')
      expect(output[:webhooks]['newPet'][:post][:requestBody]).to be_present
    end
  end
end

describe 'OpenAPI 3.1 jsonSchemaDialect' do
  it 'exports jsonSchemaDialect when set' do
    spec = GrapeSwagger::OpenAPI::Document.new
    spec.info.title = 'Test API'
    spec.info.version = '1.0'
    spec.json_schema_dialect = 'https://json-schema.org/draft/2020-12/schema'

    exporter = GrapeSwagger::Exporter::OAS31.new(spec)
    output = exporter.export

    expect(output[:jsonSchemaDialect]).to eq('https://json-schema.org/draft/2020-12/schema')
  end

  it 'places jsonSchemaDialect after openapi version' do
    spec = GrapeSwagger::OpenAPI::Document.new
    spec.info.title = 'Test API'
    spec.info.version = '1.0'
    spec.json_schema_dialect = 'https://json-schema.org/draft/2020-12/schema'

    exporter = GrapeSwagger::Exporter::OAS31.new(spec)
    output = exporter.export

    keys = output.keys
    openapi_index = keys.index(:openapi)
    dialect_index = keys.index(:jsonSchemaDialect)
    info_index = keys.index(:info)

    expect(dialect_index).to be > openapi_index
    expect(dialect_index).to be < info_index
  end
end

describe 'OpenAPI 3.1 schema $schema keyword' do
  it 'exports $schema keyword when set on schema' do
    spec = GrapeSwagger::OpenAPI::Document.new
    spec.info.title = 'Test API'
    spec.info.version = '1.0'

    schema = GrapeSwagger::OpenAPI::Schema.new(type: 'object')
    schema.json_schema = 'https://json-schema.org/draft/2020-12/schema'
    schema.add_property('name', GrapeSwagger::OpenAPI::Schema.new(type: 'string'))

    spec.components.add_schema('MyModel', schema)

    exporter = GrapeSwagger::Exporter::OAS31.new(spec)
    output = exporter.export

    expect(output[:components][:schemas]['MyModel'][:$schema]).to eq('https://json-schema.org/draft/2020-12/schema')
  end
end

describe 'OpenAPI 3.1 contentMediaType and contentEncoding' do
  it 'exports contentMediaType for binary content' do
    spec = GrapeSwagger::OpenAPI::Document.new
    spec.info.title = 'Test API'
    spec.info.version = '1.0'

    schema = GrapeSwagger::OpenAPI::Schema.new(type: 'string')
    schema.content_media_type = 'image/png'
    schema.content_encoding = 'base64'

    spec.components.add_schema('ImageData', schema)

    exporter = GrapeSwagger::Exporter::OAS31.new(spec)
    output = exporter.export

    image_schema = output[:components][:schemas]['ImageData']
    expect(image_schema[:contentMediaType]).to eq('image/png')
    expect(image_schema[:contentEncoding]).to eq('base64')
  end

  it 'does not export contentMediaType in OAS 3.0' do
    spec = GrapeSwagger::OpenAPI::Document.new
    spec.info.title = 'Test API'
    spec.info.version = '1.0'

    schema = GrapeSwagger::OpenAPI::Schema.new(type: 'string')
    schema.content_media_type = 'image/png'
    schema.content_encoding = 'base64'

    spec.components.add_schema('ImageData', schema)

    exporter = GrapeSwagger::Exporter::OAS30.new(spec)
    output = exporter.export

    image_schema = output[:components][:schemas]['ImageData']
    expect(image_schema).not_to have_key(:contentMediaType)
    expect(image_schema).not_to have_key(:contentEncoding)
  end
end
