require 'spec_helper'

describe 'exposing' do
  before :all do
    module TheApi
      module Entities
        class ApiError < Grape::Entity
          expose :code, documentation: { type: Integer }
          expose :message, documentation: { type: String }
        end

        class ResponseItem < Grape::Entity
          expose :id, documentation: { type: Integer }
          expose :name, documentation: { type: String }
        end

        class UseResponse < Grape::Entity
          expose :description, documentation: { type: String }
          expose :items, as: '$responses', using: Entities::ResponseItem, documentation: { is_array: true }
        end
      end

      class ResponseApi < Grape::API
        format :json

        desc 'This returns something',
          params: Entities::UseResponse.documentation,
          failure: [{code: 400, message: 'NotFound', model: Entities::ApiError}]
        get '/params_response' do
          { "declared_params" => declared(params) }
        end

        desc 'This returns something',
          entity: Entities::UseResponse,
          failure: [{code: 400, message: 'NotFound', model: Entities::ApiError}]
        get '/entity_response' do
          { "declared_params" => declared(params) }
        end

        # desc 'This returns something',
        #   failure: [{code: 400, message: 'NotFound', model: Entities::ApiError}]
        # get '/present_response' do
        #   foo = OpenStruct.new id: 1, name: 'bar'
        #   something = OpenStruct.new description: 'something', item: foo
        #   present :somethings, something, with: Entities::UseResponse
        # end

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::ResponseApi
  end



  # describe "presented response from entity" do
  #   subject do
  #     get '/swagger_doc/present_response'
  #     JSON.parse(last_response.body)
  #   end
  #
  #   describe "uses entity as response object" do
  #     specify do
  #       ap subject
  #     end
  #   end
  # end

  describe "response from entity" do
    subject do
      get '/swagger_doc/entity_response'
      JSON.parse(last_response.body)
    end

    describe "uses entity as response object" do
      specify do
        expect(subject).to eql({
          "info"=>{"title"=>"API title", "version"=>"v1"},
          "swagger"=>"2.0",
          "produces"=>["application/json"],
          "host"=>"example.org",
          "schemes"=>["https", "http"],
          "paths"=>{
            "/entity_response"=>{
              "get"=>{
                "produces"=>["application/json"],
                "responses"=>{
                  "200"=>{"description"=>"This returns something", "schema"=>{"$ref"=>"#/definitions/UseResponse"}},
                  "400"=>{"description"=>"NotFound", "schema"=>{"$ref"=>"#/definitions/ApiError"}}}}}},
          "definitions"=>{
            "ResponseItem"=>{
              "type"=>"object",
              "properties"=>{"id"=>{"type"=>"integer"}, "name"=>{"type"=>"string"}}},
            "UseResponse"=>{
              "type"=>"object",
              "properties"=>{"description"=>{"type"=>"string"}, "$responses"=>{"$ref"=>"#/definitions/ResponseItem"}}},
            "ApiError"=>{
              "type"=>"object",
              "properties"=>{"code"=>{"type"=>"integer"}, "message"=>{"type"=>"string"}}}
        }})
      end
    end
  end

  describe "response params" do
    subject do
      get '/swagger_doc/params_response'
      JSON.parse(last_response.body)
    end

    describe "uses params as response object" do
      specify do
        expect(subject).to eql({
          "info"=>{"title"=>"API title", "version"=>"v1"},
          "swagger"=>"2.0",
          "produces"=>["application/json"],
          "host"=>"example.org",
          "schemes"=>["https", "http"],
          "paths"=>{
            "/params_response"=>{
              "get"=>{
                "produces"=>["application/json"],
                "responses"=>{
                  "200"=>{"description"=>"This returns something", "schema"=>{"$ref"=>"#/definitions/ParamsResponse"}},
                  "400"=>{"description"=>"NotFound", "schema"=>{"$ref"=>"#/definitions/ApiError"}}}}}},
          "definitions"=>{
            "ParamsResponse"=>{"properties"=>{"description"=>{"type"=>"string"}}},
            "ApiError"=>{
              "type"=>"object",
              "properties"=>{"code"=>{"type"=>"integer"}, "message"=>{"type"=>"string"}}}}
        })
      end
    end
  end

end
