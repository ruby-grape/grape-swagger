# frozen_string_literal: true

require 'spec_helper'

describe 'x- extensions in OAS 3.0' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApiOAS3
      class ExtensionsApi < Grape::API
        format :json

        route_setting :x_path, some: 'stuff'

        desc 'This returns something with extension on path level',
             params: Entities::UseResponse.documentation,
             failure: [{ code: 400, message: 'NotFound', model: Entities::ApiError }]
        get '/path_extension' do
          { 'declared_params' => declared(params) }
        end

        route_setting :x_operation, some: 'stuff'

        desc 'This returns something with extension on verb level',
             params: Entities::UseResponse.documentation,
             failure: [{ code: 400, message: 'NotFound', model: Entities::ApiError }]
        params do
          requires :id, type: Integer
        end
        get '/verb_extension' do
          { 'declared_params' => declared(params) }
        end

        route_setting :x_def, for: 200, some: 'stuff'

        desc 'This returns something with extension on definition level',
             params: Entities::ResponseItem.documentation,
             success: Entities::ResponseItem,
             failure: [{ code: 400, message: 'NotFound', model: Entities::ApiError }]
        get '/definitions_extension' do
          { 'declared_params' => declared(params) }
        end

        route_setting :x_def, [{ for: 422, other: 'stuff' }, { for: 200, some: 'stuff' }]

        desc 'This returns something with extension on definition level',
             success: Entities::OtherItem
        get '/non_existent_status_definitions_extension' do
          { 'declared_params' => declared(params) }
        end

        route_setting :x_def, [{ for: 422, other: 'stuff' }, { for: 200, some: 'stuff' }]

        desc 'This returns something with extension on definition level',
             success: Entities::OtherItem,
             failure: [{ code: 422, message: 'NotFound', model: Entities::SecondApiError }]
        get '/multiple_definitions_extension' do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation(openapi_version: '3.0', x: { some: 'stuff' })
      end
    end
  end

  def app
    TheApiOAS3::ExtensionsApi
  end

  describe 'OAS3 format' do
    subject do
      get '/swagger_doc/path_extension'
      JSON.parse(last_response.body)
    end

    it 'returns openapi 3.0.3' do
      expect(subject['openapi']).to eq('3.0.3')
    end

    it 'uses components/schemas instead of definitions' do
      expect(subject['definitions']).to be_nil
      expect(subject['components']['schemas']).to be_present
    end
  end

  describe 'extension on root level' do
    subject do
      get '/swagger_doc/path_extension'
      JSON.parse(last_response.body)
    end

    it 'has x- extension at root' do
      expect(subject).to include 'x-some'
      expect(subject['x-some']).to eq 'stuff'
    end
  end

  describe 'extension on verb level' do
    subject do
      get '/swagger_doc/verb_extension'
      JSON.parse(last_response.body)
    end

    it 'has x- extension on operation' do
      expect(subject['paths']['/verb_extension']['get']).to include 'x-some'
      expect(subject['paths']['/verb_extension']['get']['x-some']).to eq 'stuff'
    end
  end

  describe 'schemas in components' do
    subject do
      get '/swagger_doc/definitions_extension'
      JSON.parse(last_response.body)
    end

    it 'has schemas defined in components' do
      expect(subject['components']['schemas']).to have_key('ResponseItem')
      expect(subject['components']['schemas']).to have_key('ApiError')
    end

    it 'schemas have proper structure' do
      expect(subject['components']['schemas']['ResponseItem']['type']).to eq('object')
    end
  end

  describe 'multiple schemas' do
    subject do
      get '/swagger_doc/multiple_definitions_extension'
      JSON.parse(last_response.body)
    end

    it 'has multiple schemas in components' do
      expect(subject['components']['schemas']).to have_key('OtherItem')
      expect(subject['components']['schemas']).to have_key('SecondApiError')
    end
  end
end
