require 'spec_helper'

describe 'setting of param type, such as `query`, `path`, `formData`, `body`, `header`' do
  include_context "the api entities"

  before :all do
    module TheApi
      class BodyParamTypeApi < Grape::API
        namespace :wo_entities do
          desc 'post in body /wo entity'
          params do
            requires :in_body_1, type: Integer, documentation: { desc: 'in_body_1', param_type: 'body' }
            optional :in_body_2, type: String, documentation: { desc: 'in_body_2', param_type: 'body' }
            optional :in_body_3, type: String, documentation: { desc: 'in_body_3', param_type: 'body' }
          end

          post '/in_body' do
            { "declared_params" => declared(params) }
          end

          desc 'put in body /wo entity'
          params do
            requires :key, type: Integer
            optional :in_body_1, type: Integer, documentation: { desc: 'in_body_1', param_type: 'body' }
            optional :in_body_2, type: String, documentation: { desc: 'in_body_2', param_type: 'body' }
            optional :in_body_3, type: String, documentation: { desc: 'in_body_3', param_type: 'body' }
          end

          put '/in_body/:key' do
            { "declared_params" => declared(params) }
          end
        end

        namespace :with_entities do
          desc 'post in body with entity',
            success: TheApi::Entities::ResponseItem
          params do
            requires :name, type: String, documentation: { desc: 'name', param_type: 'body' }
          end

          post '/in_body' do
            { "declared_params" => declared(params) }
          end

          desc 'put in body with entity',
            success: TheApi::Entities::ResponseItem
          params do
            requires :id, type: Integer
            optional :name, type: String, documentation: { desc: 'name', param_type: 'body' }
          end

          put '/in_body/:id' do
            { "declared_params" => declared(params) }
          end
        end

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::BodyParamTypeApi
  end

  describe 'no entity given' do
    subject do
      get '/swagger_doc/wo_entities'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/wo_entities/in_body']['post']['parameters']).to eql([
        {"name"=>"postWoEntitiesInBody", "in"=>"body", "required"=>true, "schema"=>{"$ref"=>"#/definitions/postWoEntitiesInBody"}}
      ])
    end

    specify do
      expect(subject['definitions']['postWoEntitiesInBody']).to eql({
        "description" => "post in body /wo entity",
        "type"=>"object",
        "properties"=>{
          "in_body_1"=>{"type"=>"integer", "format"=>"int32", "description"=>"in_body_1"},
          "in_body_2"=>{"type"=>"string", "description"=>"in_body_2"},
          "in_body_3"=>{"type"=>"string", "description"=>"in_body_3"}
        },
        "required"=>["in_body_1"]
      })
    end

    specify do
      expect(subject['paths']['/wo_entities/in_body/{key}']['put']['parameters']).to eql([
        {"in"=>"path", "name"=>"key", "type"=>"integer", "format"=>"int32", "required"=>true},
        {"name"=>"putWoEntitiesInBodyKey", "in"=>"body", "required"=>true, "schema"=>{"$ref"=>"#/definitions/putWoEntitiesInBodyKey"}}
      ])
    end

    specify do
      expect(subject['definitions']['putWoEntitiesInBodyKey']).to eql({
        "description" => "put in body /wo entity",
        "type"=>"object",
        "properties"=>{
          "key"=>{"type"=>"integer", "format"=>"int32", "readOnly"=>true},
          "in_body_1"=>{"type"=>"integer", "format"=>"int32", "description"=>"in_body_1"},
          "in_body_2"=>{"type"=>"string", "description"=>"in_body_2"},
          "in_body_3"=>{"type"=>"string", "description"=>"in_body_3"}
        }
      })
    end
  end

  describe 'entity given' do
    subject do
      get '/swagger_doc/with_entities'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/with_entities/in_body']['post']['parameters']).to eql([
        {"name"=>"ResponseItem", "in"=>"body", "required"=>true, "schema"=>{"$ref"=>"#/definitions/postRequestResponseItem"}}
      ])
    end

    specify do
      expect(subject['definitions']['postRequestResponseItem']).to eql({
        "description" => "post in body with entity",
        "type"=>"object",
        "properties"=>{
          "name"=>{"type"=>"string", "description"=>"name"}},
          "required"=>["name"]
      })
    end

    specify do
      expect(subject['paths']['/with_entities/in_body/{id}']['put']['parameters']).to eql([
        {"in"=>"path", "name"=>"id", "type"=>"integer", "format"=>"int32", "required"=>true},
        {"name"=>"ResponseItem", "in"=>"body", "required"=>true, "schema"=>{"$ref"=>"#/definitions/putRequestResponseItem"}}
      ])
    end

    specify do
      expect(subject['definitions']['putRequestResponseItem']).to eql({
        "description" => "put in body with entity",
        "type"=>"object",
        "properties"=>{
          "id"=>{"type"=>"integer", "format"=>"int32", "readOnly"=>true},
          "name"=>{"type"=>"string", "description"=>"name"}}
      })
    end
  end
end
