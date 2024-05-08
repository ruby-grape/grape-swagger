# frozen_string_literal: true

require 'spec_helper'

describe 'definitions/models' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class ModelApi < Grape::API
        format :json

        add_swagger_documentation openapi_version: '3.0', models: [
          ::Entities::UseResponse,
          ::Entities::ApiError,
          ::Entities::RecursiveModel,
          ::Entities::DocumentedHashAndArrayModel
        ]
      end
    end
  end

  def app
    TheApi::ModelApi
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  specify do
    expect(subject).to include 'components'
    expect(subject['components']['schemas']).to include(swagger_definitions_models)
  end
end
