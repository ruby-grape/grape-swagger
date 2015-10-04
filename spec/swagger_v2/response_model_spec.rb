require 'spec_helper'

describe 'responseModel' do
  before :all do
    module MyAPI
      module Entities
        class Kind < Grape::Entity
          expose :title, documentation: { type: 'string', desc: 'Title of the kind.' }
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

        class Something < Grape::Entity
          expose :text, documentation: { type: 'string', desc: 'Content of something.' }
          expose :kind, using: Kind, documentation: { type: 'MyAPI::Kind', desc: 'The kind of this something.' }
          expose :kind2, using: Kind, documentation: { desc: 'Secondary kind.' }
          expose :kind3, using: MyAPI::Entities::Kind, documentation: { desc: 'Tertiary kind.' }
          expose :tags, using: MyAPI::Entities::Tag, documentation: { desc: 'Tags.', is_array: true }
          expose :relation, using: MyAPI::Entities::Relation, documentation: { type: 'MyAPI::Relation', desc: 'A related model.' }
        end
      end

      class ResponseModelApi < Grape::API
        format :json
        desc 'This returns something or an error',
             entity: Entities::Something,
             http_codes: [
               { code: 200, message: 'OK', model: Entities::Something },
               { code: 403, message: 'Refused to return something', model: Entities::Error }
             ]
        params do
          optional :id, type: Integer
        end
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
    expect(subject['paths']["/something/{id}"]["get"]["responses"]).to eq(
      {
        "200"=>{
          "description"=>"OK",
          "schema"=>{"$ref"=>"#/definitions/Something"}
        },
        "403"=>{
          "description"=>"Refused to return something",
          "schema"=>{"$ref"=>"#/definitions/Error"}
      }}
    )
    expect(subject['definitions'].keys).to include 'Error'
    expect(subject['definitions']['Error']).to eq(
      {
        "type"=>"object",
        "properties"=>{
          "code"=>{"type"=>"string"},
          "message"=>{"type"=>"string"}
      }}
    )

    expect(subject['definitions'].keys).to include 'Something'
    expect(subject['definitions']['Something']).to eq(
    { "type"=>"object",
      "properties"=>
        { "text"=>{"type"=>"string"},
          "kind"=>{"$ref"=>"#/definitions/Kind"},
          "kind2"=>{"$ref"=>"#/definitions/Kind"},
          "kind3"=>{"$ref"=>"#/definitions/Kind"},
          "tags"=>{"$ref"=>"#/definitions/Tag"},
          "relation"=>{"$ref"=>"#/definitions/Relation"}}}
    )

    expect(subject['definitions'].keys).to include 'Kind'
    expect(subject['definitions']['Kind']).to eq(
      "type"=>"object", "properties"=>{"title"=>{"type"=>"string"}}
    )

    expect(subject['definitions'].keys).to include 'Relation'
    expect(subject['definitions']['Relation']).to eq(
      "type"=>"object", "properties"=>{"name"=>{"type"=>"string"}}
    )

    expect(subject['definitions'].keys).to include 'Tag'
    expect(subject['definitions']['Tag']).to eq(
      "type"=>"object", "properties"=>{"name"=>{"type"=>"string"}}
    )
  end
end
