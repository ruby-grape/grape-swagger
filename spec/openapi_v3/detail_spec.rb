# frozen_string_literal: true

require 'spec_helper'

describe 'summary and description (detail) in OAS 3.0' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApiOAS3
      class DetailApi < Grape::API
        format :json

        desc 'This returns something',
             detail: 'detailed description of the route',
             entity: Entities::UseResponse,
             failure: [{ code: 400, model: Entities::ApiError }]
        get '/use_detail' do
          { 'declared_params' => declared(params) }
        end

        desc 'This returns something' do
          detail 'detailed description of the route inside the `desc` block'
          entity Entities::UseResponse
          failure [{ code: 400, model: Entities::ApiError }]
        end
        get '/use_detail_block' do
          { 'declared_params' => declared(params) }
        end

        desc 'Short summary only'
        get '/summary_only' do
          {}
        end

        add_swagger_documentation openapi_version: '3.0'
      end
    end
  end

  def app
    TheApiOAS3::DetailApi
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'OAS3 format' do
    it 'returns openapi 3.0.3' do
      expect(subject['openapi']).to eq('3.0.3')
    end
  end

  describe 'detail as inline option' do
    let(:operation) { subject['paths']['/use_detail']['get'] }

    it 'has summary from desc' do
      expect(operation).to include('summary')
      expect(operation['summary']).to eq 'This returns something'
    end

    it 'has description from detail' do
      expect(operation).to include('description')
      expect(operation['description']).to eq 'detailed description of the route'
    end

    it 'has response with content wrapper' do
      expect(operation['responses']['200']['content']).to be_present
    end

    it 'has failure response with schema ref' do
      expect(operation['responses']['400']['content']['application/json']['schema']['$ref']).to eq(
        '#/components/schemas/ApiError'
      )
    end
  end

  describe 'detail inside desc block' do
    let(:operation) { subject['paths']['/use_detail_block']['get'] }

    it 'has summary from desc' do
      expect(operation).to include('summary')
      expect(operation['summary']).to eq 'This returns something'
    end

    it 'has description from detail block' do
      expect(operation).to include('description')
      expect(operation['description']).to eq 'detailed description of the route inside the `desc` block'
    end
  end

  describe 'summary only (no detail)' do
    let(:operation) { subject['paths']['/summary_only']['get'] }

    it 'has description matching summary when no detail provided' do
      # In grape-swagger, when no detail is provided, description = summary
      expect(operation['description']).to eq 'Short summary only'
    end
  end
end
