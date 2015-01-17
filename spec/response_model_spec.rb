require 'spec_helper'

describe 'responseModel' do
  before :all do
    module MyAPI
      module Entities
        class Kind < Grape::Entity
          expose :title, documentation: { type: 'string', desc: 'Title of the kind.' }
        end

        class Something < Grape::Entity
          expose :text, documentation: { type: 'string', desc: 'Content of something.' }
          expose :kind, using: Kind, documentation: { type: 'MyAPI::Kind', desc: 'The kind of this something.' }
          expose :kind2, using: Kind, documentation: { desc: 'Secondary kind.' }
          expose :kind3, using: 'MyAPI::Entities::Kind', documentation: { desc: 'Tertiary kind.' }
          expose :tags, using: 'MyAPI::Entities::Tag', documentation: { desc: 'Tags.', is_array: true }
          expose :relation, using: 'MyAPI::Entities::Relation', documentation: { type: 'MyAPI::Relation', desc: 'A related model.' }
        end

        class Relation < Grape::Entity
          expose :name, documentation: { type: 'string', desc: 'Name' }
        end

        class Tag < Grape::Entity
          expose :name, documentation: { type: 'string', desc: 'Name' }
        end

        class Error < Grape::Entity
          expose :code, documentation: { type: 'string', desc: 'Error code' }
          expose :message, documentation: { type: 'string', desc: 'Error message' }
        end
      end

      class ResponseModelApi < Grape::API
        format :json
        desc 'This returns something or an error',
             entity: Entities::Something,
             http_codes: [
               [200, 'OK', Entities::Something],
               [403, 'Refused to return something', Entities::Error]
             ]

        get '/something/:id' do
          if params[:id] == 1
            something = OpenStruct.new text: 'something'
            present something, with: Entities::Something
          else
            error = OpenStruct.new code: 'some_error', message: 'Some error'
            present error, with: Entities::Error
          end
        end

        add_swagger_documentation
      end
    end
  end

  def app
    MyAPI::ResponseModelApi
  end

  subject do
    get '/swagger_doc/something'
    JSON.parse(last_response.body)
  end

  it 'should document specified models' do
    expect(subject['apis'][0]['operations'][0]['responseMessages']).to eq(
      [
        {
          'code' => 200,
          'message' => 'OK',
          'responseModel' => 'MyAPI::Something'
        },
        {
          'code' => 403,
          'message' => 'Refused to return something',
          'responseModel' => 'MyAPI::Error'
        }
      ]
    )

    expect(subject['models'].keys).to include 'MyAPI::Error'
    expect(subject['models']['MyAPI::Error']).to eq(
      'id' => 'MyAPI::Error',
      'properties' => {
        'code' => { 'type' => 'string', 'description' => 'Error code' },
        'message' => { 'type' => 'string', 'description' => 'Error message' }
      }
    )

    expect(subject['models'].keys).to include 'MyAPI::Something'
    expect(subject['models']['MyAPI::Something']).to eq(
      'id' => 'MyAPI::Something',
      'properties' => {
        'text' => { 'type' => 'string', 'description' => 'Content of something.' },
        'kind' => { '$ref' => 'MyAPI::Kind', 'description' => 'The kind of this something.' },
        'kind2' => { '$ref' => 'MyAPI::Kind', 'description' => 'Secondary kind.' },
        'kind3' => { '$ref' => 'MyAPI::Kind', 'description' => 'Tertiary kind.' },
        'tags' => { 'items' => { '$ref' => 'MyAPI::Tag' }, 'type' => 'array', 'description' => 'Tags.' },
        'relation' => { '$ref' => 'MyAPI::Relation', 'description' => 'A related model.' }
      }
    )

    expect(subject['models'].keys).to include 'MyAPI::Kind'
    expect(subject['models']['MyAPI::Kind']).to eq(
      'id' => 'MyAPI::Kind',
      'properties' => {
        'title' => { 'type' => 'string', 'description' => 'Title of the kind.' }
      }
    )

    expect(subject['models'].keys).to include 'MyAPI::Relation'
    expect(subject['models']['MyAPI::Relation']).to eq(
      'id' => 'MyAPI::Relation',
      'properties' => {
        'name' => { 'type' => 'string', 'description' => 'Name' }
      }
    )
  end
end
