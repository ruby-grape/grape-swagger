# frozen_string_literal: true

require 'spec_helper'

describe 'Nullable fields' do
  describe 'OpenAPI 3.0' do
    before :all do
      module TheApi
        class NullableOAS30Api < Grape::API
          format :json

          desc 'Create with nullable fields'
          params do
            requires :name, type: String, desc: 'Required name'
            optional :nickname, type: String, allow_blank: true, desc: 'Optional nullable nickname'
          end
          post '/create' do
            { id: 1 }
          end

          add_swagger_documentation(openapi_version: '3.0')
        end
      end
    end

    def app
      TheApi::NullableOAS30Api
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    let(:schema) { subject['components']['schemas']['postCreate'] }

    it 'generates OpenAPI 3.0.3 version' do
      expect(subject['openapi']).to eq('3.0.3')
    end

    it 'includes both fields in schema properties' do
      expect(schema['properties']).to have_key('name')
      expect(schema['properties']).to have_key('nickname')
    end
  end

  describe 'OpenAPI 3.1' do
    before :all do
      module TheApi
        class NullableOAS31Api < Grape::API
          format :json

          desc 'Create with nullable fields'
          params do
            requires :name, type: String, desc: 'Required name'
            optional :nickname, type: String, allow_blank: true, desc: 'Optional nullable nickname'
          end
          post '/create' do
            { id: 1 }
          end

          add_swagger_documentation(openapi_version: '3.1')
        end
      end
    end

    def app
      TheApi::NullableOAS31Api
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    let(:schema) { subject['components']['schemas']['postCreate'] }

    it 'generates OpenAPI 3.1.0 version' do
      expect(subject['openapi']).to eq('3.1.0')
    end

    it 'includes both fields in schema properties' do
      expect(schema['properties']).to have_key('name')
      expect(schema['properties']).to have_key('nickname')
    end
  end

  describe 'OAS 3.0 vs 3.1 nullable handling' do
    # NOTE: This tests the structural difference in how nullable is represented
    # OAS 3.0: uses "nullable: true"
    # OAS 3.1: uses type array like ["string", "null"]

    it 'OAS 3.0 exporter uses nullable_keyword' do
      exporter = GrapeSwagger::Exporter::OAS30.new(GrapeSwagger::ApiModel::Spec.new)
      expect(exporter.send(:nullable_keyword?)).to be true
    end

    it 'OAS 3.1 exporter does not use nullable_keyword' do
      exporter = GrapeSwagger::Exporter::OAS31.new(GrapeSwagger::ApiModel::Spec.new)
      expect(exporter.send(:nullable_keyword?)).to be false
    end

    it 'exports nullable schema correctly in OAS 3.0' do
      schema = GrapeSwagger::ApiModel::Schema.new(type: 'string', nullable: true)
      spec = GrapeSwagger::ApiModel::Spec.new
      spec.components.add_schema('Test', schema)

      exporter = GrapeSwagger::Exporter::OAS30.new(spec)
      output = exporter.export

      expect(output[:components][:schemas]['Test'][:nullable]).to eq(true)
      expect(output[:components][:schemas]['Test'][:type]).to eq('string')
    end

    it 'exports nullable schema correctly in OAS 3.1' do
      schema = GrapeSwagger::ApiModel::Schema.new(type: 'string', nullable: true)
      spec = GrapeSwagger::ApiModel::Spec.new
      spec.components.add_schema('Test', schema)

      exporter = GrapeSwagger::Exporter::OAS31.new(spec)
      output = exporter.export

      expect(output[:components][:schemas]['Test'][:type]).to eq(%w[string null])
      expect(output[:components][:schemas]['Test']).not_to have_key(:nullable)
    end
  end
end
