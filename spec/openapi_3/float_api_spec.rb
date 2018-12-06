# frozen_string_literal: true

require 'spec_helper'

describe 'Float Params' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :a_float, type: Float
      end
      post :splines do
      end

      add_swagger_documentation openapi_version: '3.0'
    end
  end

  subject do
    get '/swagger_doc/splines'
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    body['paths']['/splines']['post']['requestBody']['content']['application/x-www-form-urlencoded']
  end

  it 'converts float types' do
    expect(subject).to eq(
      'schema' => {
        'properties' => {
          'a_float' => { 'format' => 'float', 'type' => 'number' }
        },
        'required' => ['a_float'],
        'type' => 'object'
      }
    )
  end
end
