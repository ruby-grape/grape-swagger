require 'spec_helper'

describe 'Mutually exclusive group params' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :required_group, type: Hash do
          group :param_group_1, type: Hash do
            requires :param_1, type: String
          end
          optional :param_group_2, type: Array do
            requires :param_2, type: String
          end
          mutually_exclusive :param_group_1, :param_group_2
        end
      end
      post '/groups' do
        {}
      end

      add_swagger_documentation
    end
  end

  it 'retrieves the documentation for group parameters' do
    get '/swagger_doc/groups'

    body = JSON.parse last_response.body
    parameters = body['apis'].first['operations'].first['parameters']
    expect(parameters).to eq [
      { 'paramType' => 'form', 'name' => 'required_group[param_group_1][param_1]', 'description' => nil, 'type' => 'string', 'required' => false, 'allowMultiple' => false },
      { 'paramType' => 'form', 'name' => 'required_group[param_group_2][param_2]', 'description' => nil, 'type' => 'string', 'required' => false, 'allowMultiple' => false }]
  end
end
