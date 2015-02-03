require 'spec_helper'

describe 'Range Params' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :letter, type: Virtus::Attribute::String, values: 'a'..'z'
      end
      post :letter do
      end

      params do
        requires :number, type: Virtus::Attribute::Integer, values: -5..5
      end
      post :integer do
      end

      add_swagger_documentation
    end
  end

  subject(:letter) do
    get '/swagger_doc/letter'
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    body['apis'].first['operations'].first['parameters']
  end

  it 'has letter range values' do
    expect(letter).to eq [
      { 'paramType' => 'form', 'name' => 'letter', 'description' => nil, 'type' => 'string', 'required' => true, 'allowMultiple' => false, 'enum' => ('a'..'z').to_a }
    ]
  end

  subject(:number) do
    get '/swagger_doc/integer'
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    body['apis'].first['operations'].first['parameters']
  end

  it 'has number range values' do
    expect(number).to eq [
      { 'paramType' => 'form', 'name' => 'number', 'description' => nil, 'type' => 'integer', 'required' => true, 'allowMultiple' => false, 'format' => 'int32', 'enum' => (-5..5).to_a }
    ]
  end

end
