require 'spec_helper'

describe 'Form Params' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :name, type: String, desc: 'name of item'
      end
      post '/items' do
        {}
      end

      params do
        requires :id, type: Integer, desc: 'id of item'
        requires :name, type: String, desc: 'name of item'
        requires :conditions, type: Integer, desc: 'conditions of item', values: [1, 2, 3]
      end
      put '/items/:id' do
        {}
      end

      params do
        requires :id, type: Integer, desc: 'id of item'
        requires :name, type: String, desc: 'name of item'
        optional :conditions, type: String, desc: 'conditions of item', values: proc { %w(1 2) }
      end
      patch '/items/:id' do
        {}
      end

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

  subject do
    get '/swagger_doc/items.json'
    JSON.parse(last_response.body)
  end

  it 'retrieves the documentation form params' do
    expect(subject['apis']).to eq([
      {
        'path' => '/items.{format}',
        'operations' => [
          {
            'notes' => '',
            'summary' => '',
            'nickname' => 'POST-items---format-',
            'method' => 'POST',
            'parameters' => [{ 'paramType' => 'form', 'name' => 'name', 'description' => 'name of item', 'type' => 'string', 'required' => true, 'allowMultiple' => false }],
            'type' => 'void'
          }
        ]
      }, {
        'path' => '/items/{id}.{format}',
        'operations' => [
          {
            'notes' => '',
            'summary' => '',
            'nickname' => 'PUT-items--id---format-',
            'method' => 'PUT',
            'parameters' => [
              { 'paramType' => 'path', 'name' => 'id', 'description' => 'id of item', 'type' => 'integer', 'required' => true, 'allowMultiple' => false, 'format' => 'int32' },
              { 'paramType' => 'form', 'name' => 'name', 'description' => 'name of item', 'type' => 'string', 'required' => true, 'allowMultiple' => false },
              { 'paramType' => 'form', 'name' => 'conditions', 'description' => 'conditions of item', 'type' => 'integer', 'required' => true, 'allowMultiple' => false, 'format' => 'int32', 'enum' => [1, 2, 3] }
            ],
            'type' => 'void'
          },
          {
            'notes' => '',
            'summary' => '',
            'nickname' => 'PATCH-items--id---format-',
            'method' => 'PATCH',
            'parameters' => [
              { 'paramType' => 'path', 'name' => 'id', 'description' => 'id of item', 'type' => 'integer', 'required' => true, 'allowMultiple' => false, 'format' => 'int32' },
              { 'paramType' => 'form', 'name' => 'name', 'description' => 'name of item', 'type' => 'string', 'required' => true, 'allowMultiple' => false },
              { 'paramType' => 'form', 'name' => 'conditions', 'description' => 'conditions of item', 'type' => 'string', 'required' => false, 'allowMultiple' => false, 'enum' => %w(1 2) }
            ],
            'type' => 'void'
          }
        ]
      }])
  end

  it 'retrieves the documentation for group parameters' do
    get '/swagger_doc/groups.json'

    body = JSON.parse last_response.body
    parameters = body['apis'].first['operations'].first['parameters']
    expect(parameters).to eq [
      { 'paramType' => 'form', 'name' => 'required_group[required_param_1]', 'description' => nil, 'type' => 'string', 'required' => true, 'allowMultiple' => false },
      { 'paramType' => 'form', 'name' => 'required_group[required_param_2]', 'description' => nil, 'type' => 'string', 'required' => true, 'allowMultiple' => false }]

  end
end
