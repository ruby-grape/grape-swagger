# frozen_string_literal: true

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
        optional :conditions, type: String, desc: 'conditions of item', values: proc { %w[1 2] }
      end
      patch '/items/:id' do
        {}
      end

      params do
        requires :id, type: Integer, desc: 'id of item'
        requires :name, type: String, desc: 'name of item'
        optional :conditions, type: Symbol, desc: 'conditions of item', values: %i[one two]
      end
      post '/items/:id' do
        {}
      end

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc/items'
    JSON.parse(last_response.body)
  end

  it 'retrieves the documentation form params' do
    expect(subject['paths'].length).to eq 2
    expect(subject['paths'].keys).to include('/items', '/items/{id}')
    expect(subject['paths']['/items'].keys).to include 'post'
    expect(subject['paths']['/items/{id}'].keys).to include('post', 'patch', 'put')
  end

  it 'treats Symbol parameter as form param' do
    expect(subject['paths']['/items/{id}']['post']['parameters']).to eq [
      { 'in' => 'path', 'name' => 'id', 'description' => 'id of item', 'type' => 'integer', 'required' => true, 'format' => 'int32' },
      { 'in' => 'formData', 'name' => 'name', 'description' => 'name of item', 'type' => 'string', 'required' => true },
      { 'in' => 'formData', 'name' => 'conditions', 'description' => 'conditions of item', 'type' => 'string', 'required' => false, 'enum' => %w[one two] }
    ]
  end
end
