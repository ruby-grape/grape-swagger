require 'spec_helper'

describe 'Group Params' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :required_group, type: Hash do
          requires :required_param_1
          requires :required_param_2
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
      { 'paramType' => 'form', 'name' => 'required_group[required_param_1]', 'description' => '', 'type' => 'string', 'required' => true, 'allowMultiple' => false },
      { 'paramType' => 'form', 'name' => 'required_group[required_param_2]', 'description' => '', 'type' => 'string', 'required' => true, 'allowMultiple' => false }]
  end
end
