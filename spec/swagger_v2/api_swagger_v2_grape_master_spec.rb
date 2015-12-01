require 'spec_helper'

describe 'support for grape master' do
  before :all do
    module GrapeMaster
      module Entities
        class Kind < Grape::Entity
          expose :somethin, as: :id, documentation: { type: Integer, desc: 'Title of the kind.' }
        end

        class Relation < Grape::Entity
          expose :formatted_name, as: :name, documentation: { type: String, desc: 'Name' }

        end
        class Tag < Grape::Entity
          expose :name, documentation: { type: 'string', desc: 'Name' }

        end

        class SomeEntity < Grape::Entity
          expose :comment, as: :text, documentation: { type: 'string', desc: 'Content of something.' }
          expose :kind, using: Kind, documentation: { type: 'GrapeMaster::Kind', desc: 'The kind of this something.' }
          expose :kind2, using: Kind, documentation: { desc: 'Secondary kind.' }
          expose :kind3, using: GrapeMaster::Entities::Kind, documentation: { desc: 'Tertiary kind.' }
          expose :tags, using: GrapeMaster::Entities::Tag, documentation: { desc: 'Tags.', is_array: true }
          expose :relation, using: GrapeMaster::Entities::Relation, documentation: { type: 'GrapeMaster::Relation', desc: 'A related model.' }
        end

        class ApiError < Grape::Entity
          expose :status_code, documentation: { type: Integer, desc: 'status code' }
          expose :message, documentation: { type: String, desc: 'error message' }
        end

        class ApiError2 < Grape::Entity
          expose :status, documentation: { type: Integer, desc: 'status' }
          expose :message, documentation: { type: String, desc: 'message' }
        end
      end

      class DescribeApi < Grape::API
        format :json

        namespace :some_entity do
          desc 'This returns something',
            is_array: true,
            success: Entities::SomeEntity,
            failure: [[ 422, 'EntitiesOutError', Entities::ApiError ]]
          get do
            something = OpenStruct.new text: 'something'
            present something, with: Entities::SomeEntity
          end

          desc 'This returns something',
            success: Entities::SomeEntity,
            failure: [{ code: 422, message: 'EntitiesOutError', model: Entities::ApiError2 }]
          get ':id' do
            something = OpenStruct.new text: 'something'
            present something, with: Entities::SomeEntity
          end
        end


        add_swagger_documentation
      end
    end
  end

  def app
    GrapeMaster::DescribeApi
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  it "it prefer entity over others" do
    expect(subject).to eql({
      "info"=>{"title"=>"API title", "version"=>"v1"},
      "swagger"=>"2.0",
      "produces"=>["application/json"],
      "host"=>"example.org",
      "paths"=>{
        "/some_entity"=>{
          "get"=>{
            "produces"=>["application/json"],
            "responses"=>{
              "200"=>{
                "description"=>"This returns something",
                "schema"=>{"type"=>"array", "items"=>{"$ref"=>"#/definitions/SomeEntity"}}},
              "422"=>{
                "description"=>"EntitiesOutError",
                "schema"=>{"$ref"=>"#/definitions/ApiError"}}}}},
        "/some_entity/{id}"=>{
          "get"=>{
            "produces"=>["application/json"],
            "responses"=>{
              "200"=>{
                "description"=>"This returns something",
                "schema"=>{"$ref"=>"#/definitions/SomeEntity"}},
              "422"=>{
                "description"=>"EntitiesOutError",
                "schema"=>{"$ref"=>"#/definitions/ApiError2"}}}}}},
      "definitions"=>{
        "SomeEntity"=>{
          "type"=>"object",
          "properties"=>{"text"=>{"type"=>"string"},
        "kind"=>{"$ref"=>"#/definitions/Kind"},
        "kind2"=>{"$ref"=>"#/definitions/Kind"},
        "kind3"=>{"$ref"=>"#/definitions/Kind"},
        "tags"=>{"$ref"=>"#/definitions/Tag"},
        "relation"=>{"$ref"=>"#/definitions/Relation"}}},
        "Kind"=>{
          "type"=>"object",
          "properties"=>{"id"=>{"type"=>"integer"}}},
        "Tag"=>{
          "type"=>"object",
          "properties"=>{"name"=>{"type"=>"string"}}},
        "Relation"=>{
          "type"=>"object",
          "properties"=>{"name"=>{"type"=>"string"}}},
        "ApiError"=>{
          "type"=>"object",
          "properties"=>{
            "status_code"=>{"type"=>"integer"},
            "message"=>{"type"=>"string"}}},
        "ApiError2"=>{"type"=>"object",
          "properties"=>{
            "status"=>{"type"=>"integer"},
            "message"=>{"type"=>"string"}}}
      }})

  end
end
