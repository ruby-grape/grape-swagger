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

  it 'converts float types' do
    expect(subject).to eq [
      { 'in' => 'formData', 'name' => 'a_float', 'type' => 'number', 'required' => true, 'format' => 'float' }
    ]
  end
end
