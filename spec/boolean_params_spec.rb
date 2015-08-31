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

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc/splines'
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    body['apis'].first['operations'].first['parameters']
  end

  it 'converts boolean types' do
    expect(subject).to eq [
      { 'paramType' => 'form', 'name' => 'a_boolean', 'description' => '', 'type' => 'boolean', 'required' => true, 'allowMultiple' => false }
    ]
  end
end
