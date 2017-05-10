# frozen_string_literal: true

require 'spec_helper'

describe 'extensions' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
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
        get '/non_existend_status_definitions_extension' do
          { 'declared_params' => declared(params) }
        end

        route_setting :x_def, [{ for: 422, other: 'stuff' }, { for: 200, some: 'stuff' }]

        desc 'This returns something with extension on definition level',
             success: Entities::OtherItem,
             failure: [{ code: 422, message: 'NotFound', model: Entities::SecondApiError }]
        get '/multiple_definitions_extension' do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation(x: { some: 'stuff' })
      end
    end
  end

  def app
    TheApi::ExtensionsApi
  end

  describe 'extension on root level' do
    subject do
      get '/swagger_doc/path_extension'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject).to include 'x-some'
      expect(subject['x-some']).to eql 'stuff'
    end
  end

  describe 'extension on path level' do
    subject do
      get '/swagger_doc/path_extension'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/path_extension']).to include 'x-some'
      expect(subject['paths']['/path_extension']['x-some']).to eql 'stuff'
    end
  end

  describe 'extension on verb level' do
    subject do
      get '/swagger_doc/verb_extension'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/verb_extension']['get']).to include 'x-some'
      expect(subject['paths']['/verb_extension']['get']['x-some']).to eql 'stuff'
    end
  end

  describe 'extension on definition level' do
    subject do
      get '/swagger_doc/definitions_extension'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['definitions']['ResponseItem']).to include 'x-some'
      expect(subject['definitions']['ResponseItem']['x-some']).to eql 'stuff'
      expect(subject['definitions']['ApiError']).not_to include 'x-some'
    end
  end

  describe 'extension on definition level' do
    subject do
      get '/swagger_doc/multiple_definitions_extension'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['definitions']['OtherItem']).to include 'x-some'
      expect(subject['definitions']['OtherItem']['x-some']).to eql 'stuff'
      expect(subject['definitions']['SecondApiError']).to include 'x-other'
      expect(subject['definitions']['SecondApiError']['x-other']).to eql 'stuff'
    end
  end

  describe 'extension on definition level' do
    subject do
      get '/swagger_doc/non_existend_status_definitions_extension'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['definitions'].length).to eql 1
      expect(subject['definitions']['OtherItem']).to include 'x-some'
      expect(subject['definitions']['OtherItem']['x-some']).to eql 'stuff'
    end
  end
end
