require 'spec_helper'

describe 'Params Types' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :input, type: String, documentation: { param_type: 'query' }
      end
      post :action do
      end

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc/action'
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    body['apis'].first['operations'].first['parameters']
  end

  it 'reads param type correctly' do
    expect(subject).to eq [
      { 'paramType' => 'query', 'name' => 'input', 'description' => nil, 'type' => 'string', 'required' => true, 'allowMultiple' => false }
    ]
  end
end
