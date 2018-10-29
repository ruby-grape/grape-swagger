# frozen_string_literal: true

require 'spec_helper'

describe 'headers' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class HeadersApi < Grape::API
        format :json

        desc 'This returns something',
             failure: [{ code: 400, model: Entities::ApiError }],
             headers: {
               'X-Rate-Limit-Limit' => {
                 'description' => 'The number of allowed requests in the current period',
                 'type' => 'integer'
               }
             },

             entity: Entities::UseResponse
        params do
          optional :param_x, type: String, desc: 'This is a parameter', documentation: { param_type: 'query' }
        end
        get '/use_headers' do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::HeadersApi
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  specify do
    parameters = subject['paths']['/use_headers']['get']['parameters']
    expect(parameters).to include(
      'in' => 'header',
      'name' => 'X-Rate-Limit-Limit',
      'description' => 'The number of allowed requests in the current period',
      'type' => 'integer',
      'format' => 'int32',
      'required' => false
    )
    expect(parameters.size).to eq(2)
    expect(parameters.first['in']).to eq('header')
    expect(parameters.last['in']).to eq('query')
  end
end
