# frozen_string_literal: true

require 'spec_helper'

describe 'Boolean Params' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :a_boolean, type: Virtus::Attribute::Boolean
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

  it 'converts boolean types' do
    expect(subject).to eq(
      'schema' => {
        'properties' => {
          'a_boolean' => { 'type' => 'boolean' }
        },
        'required' => ['a_boolean'],
        'type' => 'object'
      }
    )
  end
end
