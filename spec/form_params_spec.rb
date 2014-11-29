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

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc/items'
    JSON.parse(last_response.body)
  end

  it 'retrieves the documentation form params' do
    expect(subject['apis'].count).to eq 2
    expect(subject['apis'][0]['path']).to start_with '/items'
    expect(subject['apis'][0]['operations'][0]['method']).to eq 'POST'
    expect(subject['apis'][1]['path']).to start_with '/items/{id}'
    expect(subject['apis'][1]['operations'][0]['method']).to eq 'PUT'
    expect(subject['apis'][1]['operations'][1]['method']).to eq 'PATCH'
  end
end
