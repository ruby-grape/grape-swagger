require 'spec_helper'

describe 'exposing' do
  include_context "the api"

  before :all do
    module TheApi
      class ResponseApi < Grape::API
        format :json

        desc 'This returns something',
          params: Entities::UseResponse.documentation,
          failure: [{code: 400, message: 'NotFound', model: Entities::ApiError}]
        get '/params_response' do
          { "declared_params" => declared(params) }
        end

        desc 'This returns something',
          entity: Entities::UseResponse,
          failure: [{code: 400, message: 'NotFound', model: Entities::ApiError}]
        get '/entity_response' do
          { "declared_params" => declared(params) }
        end

        desc 'This returns something',
          failure: [{code: 400, message: 'NotFound', model: Entities::ApiError}]
        get '/present_response' do
          foo = OpenStruct.new id: 1, name: 'bar'
          something = OpenStruct.new description: 'something', item: foo
          present :somethings, something, with: Entities::UseResponse
        end

        add_swagger_documentation hide_documentation_path: false
      end
    end
  end

  def app
    TheApi::ResponseApi
  end

  describe "shows documentation paths" do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths'].keys).to include '/swagger_doc', '/swagger_doc/{name}'
    end
  end

end
