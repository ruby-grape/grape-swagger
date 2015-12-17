require 'spec_helper'

describe 'exposing additional models' do
  include_context "the api entities"

  before :all do
    module TheApi
      class ModelApi < Grape::API
        format :json

        add_swagger_documentation models: [
          TheApi::Entities::UseResponse,
          TheApi::Entities::ApiError
        ]
      end
    end
  end

  def app
    TheApi::ModelApi
  end

  describe "adds model definitions" do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject).to include 'definitions'
      expect(subject['definitions']).to include 'ResponseItem', 'UseResponse', 'ApiError'
    end
  end
end
