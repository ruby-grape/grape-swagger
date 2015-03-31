require 'spec_helper'

describe 'referenceEntity' do
  before :all do
    module MyAPI
      module Entities
        class Something < Grape::Entity
          expose :text, documentation: { type: 'string', desc: 'Content of something.' }
        end

        class Kind < Grape::Entity
          expose :title, documentation: { type: 'string', desc: 'Title of the kind.' }
          expose :something, documentation: { type: Something, desc: 'Something interesting.' }
        end
      end

      class ResponseModelApi < Grape::API
        format :json
        desc 'This returns kind and something or an error',
             entity: Entities::Kind,
             http_codes: [
               [200, 'OK', Entities::Kind]
             ]

        get '/kind/:id' do
          kind = OpenStruct.new text: 'kind'
          present kind, with: Entities::Kind
        end

        add_swagger_documentation models: [MyAPI::Entities::Something, MyAPI::Entities::Kind]
      end
    end
  end

  def app
    MyAPI::ResponseModelApi
  end

  subject do
    get '/swagger_doc/kind'
    JSON.parse(last_response.body)
  end

  it 'should document specified models' do
    expect(subject['models'].keys).to include 'MyAPI::Something'
    expect(subject['models']['MyAPI::Something']).to eq(
      'id' => 'MyAPI::Something',
      'properties' => {
        'text' => { 'type' => 'string', 'description' => 'Content of something.' }
      }
    )

    expect(subject['models'].keys).to include 'MyAPI::Kind'
    expect(subject['models']['MyAPI::Kind']).to eq(
      'id' => 'MyAPI::Kind',
      'properties' => {
        'title' => { 'type' => 'string', 'description' => 'Title of the kind.' },
        'something' => { '$ref' => 'MyAPI::Something', 'description' => 'Something interesting.' }
      }
    )
  end
end
