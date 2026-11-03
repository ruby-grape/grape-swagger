# frozen_string_literal: true

require 'spec_helper'

describe 'additional_properties in OpenAPI 3.0' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :things do
        class Element < Grape::Entity
          expose :id
        end

        params do
          optional :closed, type: Hash, documentation: { additional_properties: false, in: 'body' } do
            requires :only
          end
          optional :open, type: Hash, documentation: { additional_properties: true }
          optional :type_limited, type: Hash, documentation: { additional_properties: String }
          optional :ref_limited, type: Hash, documentation: { additional_properties: Element }
          optional :fallback, type: Hash, documentation: { additional_properties: { type: 'integer' } }
        end
        post do
          present params
        end
      end

      add_swagger_documentation format: :json, openapi_version: '3.0', models: [Element]
    end
  end

  subject do
    get '/swagger_doc/things'
    JSON.parse(last_response.body)
  end

  describe 'OpenAPI version' do
    it 'returns OAS 3.0' do
      expect(subject['openapi']).to eq('3.0.3')
    end
  end

  describe 'POST request body' do
    let(:operation) { subject['paths']['/things']['post'] }

    it 'has requestBody instead of body parameter' do
      params = operation['parameters'] || []
      body_params = params.select { |p| p['in'] == 'body' }
      expect(body_params).to be_empty
      expect(operation['requestBody']).to be_present
    end

    it 'references schema in components' do
      expect(operation['requestBody']['content']['application/json']['schema']).to eq(
        { '$ref' => '#/components/schemas/postThings' }
      )
    end
  end

  describe 'schema with additional_properties' do
    let(:schema) { subject['components']['schemas']['postThings'] }

    it 'has object type' do
      expect(schema['type']).to eq('object')
    end

    describe 'closed property (additional_properties: false)' do
      let(:closed) { schema['properties']['closed'] }

      it 'sets additionalProperties to false' do
        expect(closed['additionalProperties']).to eq(false)
      end

      it 'has nested properties' do
        expect(closed['properties']['only']).to eq({ 'type' => 'string' })
      end

      it 'marks required fields' do
        expect(closed['required']).to eq(['only'])
      end
    end

    describe 'open property (additional_properties: true)' do
      let(:open_prop) { schema['properties']['open'] }

      it 'sets additionalProperties to true' do
        expect(open_prop['additionalProperties']).to eq(true)
      end
    end

    describe 'type_limited property (additional_properties: String)' do
      let(:type_limited) { schema['properties']['type_limited'] }

      it 'sets additionalProperties to type schema' do
        expect(type_limited['additionalProperties']).to eq({ 'type' => 'string' })
      end
    end

    describe 'ref_limited property (additional_properties: Entity)' do
      let(:ref_limited) { schema['properties']['ref_limited'] }

      it 'sets additionalProperties to $ref using components/schemas path' do
        expect(ref_limited['additionalProperties']).to eq(
          { '$ref' => '#/components/schemas/Element' }
        )
      end
    end

    describe 'fallback property (additional_properties: hash)' do
      let(:fallback) { schema['properties']['fallback'] }

      it 'sets additionalProperties from hash' do
        expect(fallback['additionalProperties']).to eq({ 'type' => 'integer' })
      end
    end
  end

  describe 'Element schema in components' do
    it 'defines Element schema' do
      expect(subject['components']['schemas']).to have_key('Element')
    end
  end
end
