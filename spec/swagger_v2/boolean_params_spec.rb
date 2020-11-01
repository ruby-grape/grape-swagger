# frozen_string_literal: true

require 'spec_helper'

describe 'Boolean Params' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :a_boolean, type: Grape::API::Boolean
      end
      post :splines do
        { message: 'hi' }
      end

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc/splines'
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    body['paths']['/splines']['post']['parameters']
  end

  it 'converts boolean types' do
    expect(subject).to eq [
      { 'in' => 'formData', 'name' => 'a_boolean', 'type' => 'boolean', 'required' => true }
    ]
  end
end
