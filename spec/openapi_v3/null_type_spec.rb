# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1 type: null support' do
  describe 'entity with null type property using string type' do
    before :all do
      module NullTypeStringTest
        module Entities
          class NullableItem < Grape::Entity
            expose :id, documentation: { type: Integer, required: true }
            expose :name, documentation: { type: String, required: true }
            # A property that is always null (e.g., placeholder for future use)
            expose :deprecated_field, documentation: { type: 'null', desc: 'This field is always null' }
          end
        end

        class API31 < Grape::API
          format :json
          desc 'Get item', success: Entities::NullableItem
          get('/item') { {} }
          add_swagger_documentation(openapi_version: '3.1')
        end

        class API30 < Grape::API
          format :json
          desc 'Get item', success: Entities::NullableItem
          get('/item') { {} }
          add_swagger_documentation(openapi_version: '3.0')
        end
      end
    end

    describe 'OpenAPI 3.1' do
      def app
        NullTypeStringTest::API31
      end

      subject do
        get '/swagger_doc'
        JSON.parse(last_response.body)
      end

      let(:schema) do
        subject['components']['schemas'].find { |name, _| name.include?('NullableItem') }&.last
      end

      it 'has openapi 3.1.0 version' do
        expect(subject['openapi']).to eq('3.1.0')
      end

      it 'has type: null for deprecated_field' do
        expect(schema['properties']['deprecated_field']['type']).to eq('null')
      end

      it 'preserves description for null type property' do
        expect(schema['properties']['deprecated_field']['description']).to eq('This field is always null')
      end
    end

    describe 'OpenAPI 3.0' do
      def app
        NullTypeStringTest::API30
      end

      subject do
        get '/swagger_doc'
        JSON.parse(last_response.body)
      end

      let(:schema) do
        subject['components']['schemas'].find { |name, _| name.include?('NullableItem') }&.last
      end

      it 'has openapi 3.0.3 version' do
        expect(subject['openapi']).to eq('3.0.3')
      end

      it 'converts null type to nullable in OAS 3.0' do
        # OAS 3.0 doesn't support type: null, so we use nullable: true
        deprecated_field = schema['properties']['deprecated_field']
        expect(deprecated_field['nullable']).to be true
        expect(deprecated_field['type']).to be_nil
      end
    end
  end

  describe 'parameter with null type in grape params' do
    before :all do
      module NullParamGrapeTest
        class API31 < Grape::API
          format :json

          desc 'Endpoint with various param types'
          params do
            requires :id, type: Integer, desc: 'ID field'
            optional :name, type: String, desc: 'Name field'
          end
          post '/test' do
            { status: 'ok' }
          end

          add_swagger_documentation(openapi_version: '3.1')
        end
      end
    end

    def app
      NullParamGrapeTest::API31
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates valid OpenAPI 3.1 output' do
      expect(subject['openapi']).to eq('3.1.0')
    end

    it 'has request body with proper types' do
      operation = subject['paths']['/test']['post']
      expect(operation['requestBody']).to be_present
    end
  end

  describe 'null type in mixed schema definitions' do
    before :all do
      module NullTypeMixedTest
        module Entities
          class MixedItem < Grape::Entity
            expose :id, documentation: { type: Integer, required: true }
            expose :string_field, documentation: { type: String }
            expose :null_field, documentation: { type: 'null', desc: 'Always null' }
            expose :number_field, documentation: { type: Float }
          end
        end

        class API31 < Grape::API
          format :json
          desc 'Get mixed', success: Entities::MixedItem
          get('/mixed') { {} }
          add_swagger_documentation(openapi_version: '3.1')
        end
      end
    end

    def app
      NullTypeMixedTest::API31
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    let(:schema) do
      subject['components']['schemas'].find { |name, _| name.include?('MixedItem') }&.last
    end

    it 'preserves other types alongside null type' do
      expect(schema['properties']['string_field']['type']).to eq('string')
      expect(schema['properties']['number_field']['type']).to eq('number')
    end

    it 'has type: null for null_field' do
      expect(schema['properties']['null_field']['type']).to eq('null')
    end

    it 'has all expected properties' do
      expect(schema['properties'].keys).to include('id', 'string_field', 'null_field', 'number_field')
    end
  end
end
