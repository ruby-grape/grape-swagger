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

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc/splines'
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    body['apis'].first['operations'].first['parameters']
  end

  it 'converts float types' do
    expect(subject).to eq [
      { 'paramType' => 'form', 'name' => 'a_float', 'description' => '', 'type' => 'number', 'format' => 'float', 'required' => true, 'allowMultiple' => false }
    ]
  end
end
