# frozen_string_literal: true

require 'spec_helper'

describe 'definitions/models' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class ModelApi < Grape::API
        format :json

        add_swagger_documentation models: [
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
    expect(subject).to include 'definitions'
    expect(subject['definitions']).to include(swagger_definitions_models)
  end
end
