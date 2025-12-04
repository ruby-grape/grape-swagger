# frozen_string_literal: true

require 'spec_helper'

describe 'Nullable handling in OAS 3.0 vs 3.1' do
  include_context "#{MODEL_PARSER} swagger example"

  describe 'OAS 3.0 nullable via documentation option' do
    before :all do
      module NullableTest30
        module Entities
          class Item < Grape::Entity
            expose :id, documentation: { type: Integer, desc: 'ID' }
            expose :name, documentation: { type: String, desc: 'Name' }
            expose :nickname, documentation: { type: String, desc: 'Optional nickname', nullable: true }
            expose :description, documentation: { type: String, desc: 'Description', x: { nullable: true } }
          end
        end

        class API < Grape::API
          format :json

          desc 'Create item',
               success: { code: 201, model: Entities::Item }
          params do
            requires :name, type: String, desc: 'Name'
            optional :nickname, type: String, documentation: { nullable: true }, desc: 'Nullable nickname'
            optional :age, type: Integer, allow_blank: true, desc: 'Optional age (allow_blank)'
          end
          post '/items' do
            present({}, with: Entities::Item)
          end

          add_swagger_documentation(openapi_version: '3.0')
        end
      end
    end

    def app
      NullableTest30::API
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    describe 'request body field with documentation: { nullable: true }' do
      let(:request_schema) { subject['components']['schemas']['postItems'] }

      it 'marks field as nullable in request schema' do
        nickname = request_schema['properties']['nickname']
        expect(nickname['nullable']).to eq(true)
      end
    end
  end

  describe 'OAS 3.1 nullable handling' do
    before :all do
      module NullableTest31
        module Entities
          class Item < Grape::Entity
            expose :id, documentation: { type: Integer, desc: 'ID' }
            expose :name, documentation: { type: String, desc: 'Name' }
            expose :nickname, documentation: { type: String, desc: 'Optional nickname', nullable: true }
          end
        end

        class API < Grape::API
          format :json

          desc 'Create item',
               success: { code: 201, model: Entities::Item }
          params do
            requires :name, type: String, desc: 'Name'
            optional :nickname, type: String, documentation: { nullable: true }, desc: 'Nullable nickname'
          end
          post '/items' do
            present({}, with: Entities::Item)
          end

          add_swagger_documentation(openapi_version: '3.1')
        end
      end
    end

    def app
      NullableTest31::API
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    describe 'request body field with documentation: { nullable: true }' do
      let(:request_schema) { subject['components']['schemas']['postItems'] }

      it 'uses type array for nullable in request schema' do
        nickname = request_schema['properties']['nickname']
        expect(nickname['type']).to eq(%w[string null])
        expect(nickname).not_to have_key('nullable')
      end
    end
  end

  describe 'Direct exporter tests' do
    it 'OAS 3.0: converts schema.nullable to nullable: true' do
      schema = GrapeSwagger::ApiModel::Schema.new(type: 'string', nullable: true)
      spec = GrapeSwagger::ApiModel::Spec.new
      spec.components.add_schema('Test', schema)

      exporter = GrapeSwagger::Exporter::OAS30.new(spec)
      output = exporter.export

      expect(output[:components][:schemas]['Test'][:nullable]).to eq(true)
      expect(output[:components][:schemas]['Test'][:type]).to eq('string')
    end

    it 'OAS 3.1: converts schema.nullable to type array' do
      schema = GrapeSwagger::ApiModel::Schema.new(type: 'string', nullable: true)
      spec = GrapeSwagger::ApiModel::Spec.new
      spec.components.add_schema('Test', schema)

      exporter = GrapeSwagger::Exporter::OAS31.new(spec)
      output = exporter.export

      expect(output[:components][:schemas]['Test'][:type]).to eq(%w[string null])
      expect(output[:components][:schemas]['Test']).not_to have_key(:nullable)
    end

    it 'OAS 3.0: nested property with nullable' do
      schema = GrapeSwagger::ApiModel::Schema.new(type: 'object')
      schema.add_property('name', GrapeSwagger::ApiModel::Schema.new(type: 'string'))
      nullable_prop = GrapeSwagger::ApiModel::Schema.new(type: 'string', nullable: true)
      schema.add_property('nickname', nullable_prop)

      spec = GrapeSwagger::ApiModel::Spec.new
      spec.components.add_schema('Test', schema)

      exporter = GrapeSwagger::Exporter::OAS30.new(spec)
      output = exporter.export

      expect(output[:components][:schemas]['Test'][:properties]['nickname'][:nullable]).to eq(true)
    end

    it 'OAS 3.1: nested property with nullable' do
      schema = GrapeSwagger::ApiModel::Schema.new(type: 'object')
      schema.add_property('name', GrapeSwagger::ApiModel::Schema.new(type: 'string'))
      nullable_prop = GrapeSwagger::ApiModel::Schema.new(type: 'string', nullable: true)
      schema.add_property('nickname', nullable_prop)

      spec = GrapeSwagger::ApiModel::Spec.new
      spec.components.add_schema('Test', schema)

      exporter = GrapeSwagger::Exporter::OAS31.new(spec)
      output = exporter.export

      expect(output[:components][:schemas]['Test'][:properties]['nickname'][:type]).to eq(%w[string null])
      expect(output[:components][:schemas]['Test'][:properties]['nickname']).not_to have_key(:nullable)
    end

    it 'OAS 3.0: array items with nullable' do
      items_schema = GrapeSwagger::ApiModel::Schema.new(type: 'string', nullable: true)
      schema = GrapeSwagger::ApiModel::Schema.new(type: 'array', items: items_schema)

      spec = GrapeSwagger::ApiModel::Spec.new
      spec.components.add_schema('Test', schema)

      exporter = GrapeSwagger::Exporter::OAS30.new(spec)
      output = exporter.export

      expect(output[:components][:schemas]['Test'][:items][:nullable]).to eq(true)
    end

    it 'OAS 3.1: array items with nullable' do
      items_schema = GrapeSwagger::ApiModel::Schema.new(type: 'string', nullable: true)
      schema = GrapeSwagger::ApiModel::Schema.new(type: 'array', items: items_schema)

      spec = GrapeSwagger::ApiModel::Spec.new
      spec.components.add_schema('Test', schema)

      exporter = GrapeSwagger::Exporter::OAS31.new(spec)
      output = exporter.export

      expect(output[:components][:schemas]['Test'][:items][:type]).to eq(%w[string null])
    end
  end
end
