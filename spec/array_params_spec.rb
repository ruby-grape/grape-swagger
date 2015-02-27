require 'spec_helper'

describe 'Array Params' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :a_array, type: Array do
          requires :param_1, type: Integer
          requires :param_2, type: String
        end
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

  it 'gets array types' do
    expect(subject).to eq [
      { 'paramType' => 'form', 'name' => 'a_array[][param_1]', 'description' => nil, 'type' => 'integer', 'required' => true, 'allowMultiple' => false, 'format' => 'int32' },
      { 'paramType' => 'form', 'name' => 'a_array[][param_2]', 'description' => nil, 'type' => 'string', 'required' => true, 'allowMultiple' => false }
    ]
  end
end
