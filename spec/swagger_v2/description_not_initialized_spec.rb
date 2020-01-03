# frozen_string_literal: true

require 'spec_helper'

describe 'has no description, if details or description are nil' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class GfmRcDetailApi < Grape::API
        format :json

        desc nil,
             detail: nil,
             entity: Entities::UseResponse,
             failure: [{ code: 400, model: Entities::ApiError }]
        get '/use_gfm_rc_detail' do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::GfmRcDetailApi
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  specify do
    expect(subject['paths']['/use_gfm_rc_detail']['get']).not_to include('description')
    expect(subject['paths']['/use_gfm_rc_detail']['get']['description']).to eql(nil)
  end
end
