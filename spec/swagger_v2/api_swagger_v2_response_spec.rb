require 'spec_helper'

describe 'exposing' do
  include_context "the api entities"

  before :all do
    module TheApi
      class ResponseApi < Grape::API
        format :json

        desc 'This returns something',
          params: Entities::UseResponse.documentation,
          failure: [{code: 400, message: 'NotFound', model: Entities::ApiError}]
        post '/params_response' do
          { "declared_params" => declared(params) }
        end

        desc 'This returns something',
          entity: Entities::UseResponse,
          failure: [{code: 400, message: 'NotFound', model: Entities::ApiError}]
        get '/entity_response' do
          { "declared_params" => declared(params) }
        end

        desc 'This returns something',
          entity: Entities::UseTemResponseAsType,
          failure: [{code: 400, message: 'NotFound', model: Entities::ApiError}]
        get '/nested_type' do
          { "declared_params" => declared(params) }
        end


        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::ResponseApi
  end

  describe "uses nested type as response object" do
    subject do
      get '/swagger_doc/nested_type'
      JSON.parse(last_response.body)
    end
    specify do
      expect(subject).to eql({
        "info"=>{"title"=>"API title", "version"=>"v1"},
        "swagger"=>"2.0",
        "produces"=>["application/json"],
        "host"=>"example.org",
        "tags"=>[
          {"name"=>"params_response", "description"=>"Operations about params_responses"},
          {"name"=>"entity_response", "description"=>"Operations about entity_responses"},
          {"name"=>"nested_type", "description"=>"Operations about nested_types"}
        ],
        "schemes"=>["https", "http"],
        "paths"=>{
          "/nested_type"=>{
            "get"=>{
              "produces"=>["application/json"],
              "responses"=>{
                "200"=>{"description"=>"This returns something", "schema"=>{"$ref"=>"#/definitions/UseTemResponseAsType"}},
                "400"=>{"description"=>"NotFound", "schema"=>{"$ref"=>"#/definitions/ApiError"}}
              },
              "tags"=>["nested_type"],
              "operationId"=>"getNestedType"
        }}},
        "definitions"=>{
          "ResponseItem"=>{"type"=>"object", "properties"=>{"id"=>{"type"=>"integer"}, "name"=>{"type"=>"string"}}},
          "UseTemResponseAsType"=>{"type"=>"object", "properties"=>{"description"=>{"type"=>"string"}, "responses"=>{"$ref"=>"#/definitions/ResponseItem"}}},
          "ApiError"=>{"type"=>"object", "properties"=>{"code"=>{"type"=>"integer"}, "message"=>{"type"=>"string"}}}
      }})
    end
  end

  describe "uses entity as response object" do
    subject do
      get '/swagger_doc/entity_response'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject).to eql({
        "info"=>{"title"=>"API title", "version"=>"v1"},
        "swagger"=>"2.0",
        "produces"=>["application/json"],
        "host"=>"example.org",
        "tags" => [
          {"name"=>"params_response", "description"=>"Operations about params_responses"},
          {"name"=>"entity_response", "description"=>"Operations about entity_responses"},
          {"name"=>"nested_type", "description"=>"Operations about nested_types"}
        ],
        "schemes"=>["https", "http"],
        "paths"=>{
          "/entity_response"=>{
            "get"=>{
              "produces"=>["application/json"],
              "tags"=>["entity_response"],
              "operationId"=>"getEntityResponse",
              "responses"=>{
                "200"=>{"description"=>"This returns something", "schema"=>{"$ref"=>"#/definitions/UseResponse"}},
                "400"=>{"description"=>"NotFound", "schema"=>{"$ref"=>"#/definitions/ApiError"}}}}}},
        "definitions"=>{
          "ResponseItem"=>{
            "type"=>"object",
            "properties"=>{"id"=>{"type"=>"integer"}, "name"=>{"type"=>"string"}}},
          "UseResponse"=>{
            "type"=>"object",
            "properties"=>{"description"=>{"type"=>"string"}, "$responses"=>{"type"=>"array", "items"=>{"$ref"=>"#/definitions/ResponseItem"}}}},
          "ApiError"=>{
            "type"=>"object",
            "properties"=>{"code"=>{"type"=>"integer"}, "message"=>{"type"=>"string"}}}
      }})
    end
  end

  describe "uses params as response object" do
    subject do
      get '/swagger_doc/params_response'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject).to eql({
        "info"=>{"title"=>"API title", "version"=>"v1"},
        "swagger"=>"2.0",
        "produces"=>["application/json"],
        "host"=>"example.org",
        "tags" => [
          {"name"=>"params_response", "description"=>"Operations about params_responses"},
          {"name"=>"entity_response", "description"=>"Operations about entity_responses"},
          {"name"=>"nested_type", "description"=>"Operations about nested_types"}
        ],
        "schemes"=>["https", "http"],
        "paths"=>{
          "/params_response"=>{
            "post"=>{
              "produces"=>["application/json"],
              "consumes"=>["application/json"],
              "parameters"=>[
                {"in"=>"formData", "name"=>"description", "description"=>nil, "type"=>"string", "required"=>false, "allowMultiple"=>false},
                {"in"=>"formData", "name"=>"$responses", "description"=>nil, "type"=>"string", "required"=>false, "allowMultiple"=>true}],
              "tags"=>["params_response"],
              "operationId"=>"postParamsResponse",
              "responses"=>{
                "201"=>{"description"=>"This returns something", "schema"=>{"$ref"=>"#/definitions/ParamsResponse"}},
                "400"=>{"description"=>"NotFound", "schema"=>{"$ref"=>"#/definitions/ApiError"}}}
        }}},
        "definitions"=>{
          "ParamsResponse"=>{"properties"=>{"description"=>{"type"=>"string"}, "$responses"=>{"type"=>"string"}}},
          "ApiError"=>{"type"=>"object", "properties"=>{"code"=>{"type"=>"integer"}, "message"=>{"type"=>"string"}}}
      }})
    end
  end

end
