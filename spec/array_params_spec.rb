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

      params do
        optional :raw_array, type: Array
      end
      get :raw_array_splines do
      end

      params do
        optional :raw_array, type: Array[Integer], documentation: { is_array: true }
      end
      get :raw_array_integers do
      end

      add_swagger_documentation
    end
  end

  it 'gets array types' do
    get '/swagger_doc/splines'
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    parameters = body['apis'].first['operations'].first['parameters']
    expect(parameters).to eq [
      { 'paramType' => 'form', 'name' => 'a_array[][param_1]', 'description' => '', 'type' => 'integer', 'required' => true, 'allowMultiple' => false, 'format' => 'int32' },
      { 'paramType' => 'form', 'name' => 'a_array[][param_2]', 'description' => '', 'type' => 'string', 'required' => true, 'allowMultiple' => false }
    ]
  end

  it 'get raw array type' do
    get '/swagger_doc/raw_array_splines'
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    parameters = body['apis'].first['operations'].first['parameters']
    expect(parameters).to eq [
      { 'paramType' => 'query', 'name' => 'raw_array', 'description' => '', 'type' => 'Array', 'required' => false, 'allowMultiple' => false }
    ]
  end

  it 'get raw array integer' do
    get '/swagger_doc/raw_array_integers'
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    parameters = body['apis'].first['operations'].first['parameters']
    expect(parameters).to eq [
      { 'paramType' => 'query', 'name' => 'raw_array', 'description' => '', 'type' => 'array', 'required' => false, 'allowMultiple' => false, 'items' => { 'type' => 'integer', 'format' => 'int32' } }
    ]
  end
end
