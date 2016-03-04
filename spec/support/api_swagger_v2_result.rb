RSpec.shared_context "swagger example" do

  before :all do
    module Entities
      class Something < Grape::Entity
        expose :id, documentation: { type: Integer, desc: 'Identity of Something' }
        expose :text, documentation: { type: String, desc: 'Content of something.' }
        expose :links, documentation: { type: 'link', is_array: true }
        expose :others, documentation: { type: 'text', is_array: false }
      end

      class EnumValues < Grape::Entity
        expose :gender, documentation: { type: 'string', desc: 'Content of something.', values: %w(Male Female) }
        expose :number, documentation: { type: 'integer', desc: 'Content of something.', values: [1, 2]  }
      end


      class AliasedThing < Grape::Entity
        expose :something, as: :post, using: Entities::Something, documentation: { type: 'Something', desc: 'Reference to something.' }
      end

      class FourthLevel < Grape::Entity
        expose :text, documentation: { type: 'string' }
      end

      class ThirdLevel < Grape::Entity
        expose :parts, using: Entities::FourthLevel, documentation: { type: 'FourthLevel' }
      end

      class SecondLevel < Grape::Entity
        expose :parts, using: Entities::ThirdLevel, documentation: { type: 'ThirdLevel' }
      end

      class FirstLevel < Grape::Entity
        expose :parts, using: Entities::SecondLevel, documentation: { type: 'SecondLevel' }
      end

      class QueryInputElement < Grape::Entity
        expose :key, documentation: {
          type: String, desc: 'Name of parameter', required: true }
        expose :value, documentation: {
          type: String, desc: 'Value of parameter', required: true }
      end

      class QueryInput < Grape::Entity
        expose :elements, using: Entities::QueryInputElement, documentation: {
          type: 'QueryInputElement',
          desc: 'Set of configuration',
          param_type: 'body',
          is_array: true,
          required: true
        }
      end

      class ApiError < Grape::Entity
        expose :code, documentation: { type: Integer, desc: 'status code' }
        expose :message, documentation: { type: String, desc: 'error message' }
      end
    end
  end

  let(:swagger_json) do
    {
      "info"=>{
        "title"=>"The API title to be displayed on the API homepage.",
        "description"=>"A description of the API.",
        "termsOfServiceUrl"=>"www.The-URL-of-the-terms-and-service.com",
        "contact"=>{"contact_name"=>"Contact name", "contact_email"=>"Contact@email.com", "contact_url"=>"Contact URL"},
        "license"=>{"name"=>"The name of the license.", "url"=>"www.The-URL-of-the-license.org"},
        "version"=>"v1"
      },
      "swagger"=>"2.0",
      "produces"=>["application/json"],
      "host"=>"example.org",
      "tags"=>[{"name"=>"other_thing", "description"=>"Operations about other_things"},
        {"name"=>"thing", "description"=>"Operations about things"},
        {"name"=>"thing2", "description"=>"Operations about thing2s"},
        {"name"=>"dummy", "description"=>"Operations about dummies"}],
      "schemes"=>["https", "http"],
      "paths"=>{
        "/v3/other_thing/{elements}"=>{
          "get"=>{
            "produces"=>["application/json"],
            "parameters"=>[
              {"in"=>"array", "name"=>"elements", "description"=>"Set of configuration", "type"=>"string", "required"=>true, "allowMultiple"=>true, "items"=>{"type"=>"string"}}],
              "tags"=>["other_thing"],
              "responses"=>{"200"=>{"description"=>"nested route inside namespace", "schema"=>{"$ref"=>"#/definitions/QueryInput"}}},
              "x-amazon-apigateway-auth"=>{"type"=>"none"},
              "x-amazon-apigateway-integration"=>{"type"=>"aws", "uri"=>"foo_bar_uri", "httpMethod"=>"get"}}},
        "/thing"=>{
          "get"=>{
            "produces"=>["application/json"],
            "parameters"=>[
              {"in"=>"query", "name"=>"id", "description"=>"Identity of Something", "type"=>"integer", "required"=>false, "allowMultiple"=>false, "format"=>"int32"},
              {"in"=>"query", "name"=>"text", "description"=>"Content of something.", "type"=>"string", "required"=>false, "allowMultiple"=>false},
              {"in"=>"query", "name"=>"links", "description"=>nil, "type"=>"link", "required"=>false, "allowMultiple"=>true},
              {"in"=>"query", "name"=>"others", "description"=>nil, "type"=>"text", "required"=>false, "allowMultiple"=>false}],
              "tags"=>["thing"],
            "responses"=>{
              "200"=>{"description"=>"This gets Things.", "schema"=>{"$ref"=>"#/definitions/Thing"}},
              "401"=>{"description"=>"Unauthorized", "schema"=>{"$ref"=>"#/definitions/ApiError"}}}},
          "post"=>{
            "produces"=>["application/json"],
            "parameters"=>[
              {"in"=>"formData", "name"=>"text", "description"=>"Content of something.", "type"=>"string", "required"=>true, "allowMultiple"=>false},
              {"in"=>"body", "name"=>"links", "description"=>nil, "type"=>"Array", "required"=>true, "allowMultiple"=>true}],
            "responses"=>{
              "201"=>{"description"=>"This creates Thing.", "schema"=>{"$ref"=>"#/definitions/Something"}},
              "422"=>{"description"=>"Unprocessible Entity"}}
        }},
        "/thing/{id}"=>{
          "get"=>{
            "produces"=>["application/json"],
            "parameters"=>[
              {"in"=>"path", "name"=>"id", "description"=>nil, "type"=>"integer", "required"=>true, "allowMultiple"=>false, "format"=>"int32"}],
            "tags"=>["thing"],
            "responses"=>{
              "200"=>{"description"=>"getting a single thing", "schema"=>{"$ref"=>"#/definitions/Thing"}},
              "401"=>{"description"=>"Unauthorized"}}},
          "put"=>{
            "produces"=>["application/json"],
            "parameters"=>[
              {"in"=>"path", "name"=>"id", "description"=>nil, "type"=>"integer", "required"=>true, "allowMultiple"=>false, "format"=>"int32"},
              {"in"=>"formData", "name"=>"text", "description"=>"Content of something.", "type"=>"string", "required"=>false, "allowMultiple"=>false},
              {"in"=>"body", "name"=>"links", "description"=>nil, "type"=>"Array", "required"=>false, "allowMultiple"=>true}],
            "responses"=>{"200"=>{"description"=>"This updates Thing.", "schema"=>{"$ref"=>"#/definitions/Something"}}}},
          "delete"=>{
            "produces"=>["application/json"],
            "parameters"=>[{"in"=>"path", "name"=>"id", "description"=>nil, "type"=>"integer", "required"=>true, "allowMultiple"=>false, "format"=>"int32"}],
            "tags"=>["thing"],
            "responses"=>{"200"=>{"description"=>"This deletes Thing.", "schema"=>{"$ref"=>"#/definitions/Something"}}}
        }},
        "/thing2"=>{
          "get"=>{
            "produces"=>["application/json"],
            "tags"=>["thing2"],
            "responses"=>{
              "200"=>{"description"=>"get Horses", "schema"=>{"$ref"=>"#/definitions/Something"}},
              "401"=>{"description"=>"HorsesOutError", "schema"=>{"$ref"=>"#/definitions/ApiError"}}}
        }},
        "/dummy/{id}"=>{
          "delete"=>{
            "produces"=>["application/json"],
            "parameters"=>[{"in"=>"path", "name"=>"id", "description"=>nil, "type"=>"integer", "required"=>true, "allowMultiple"=>false, "format"=>"int32"}],
            "tags"=>["dummy"],
            "responses"=>{"200"=>{"description"=>"dummy route."}, "401"=>{"description"=>"Unauthorized"}}
      }}},
      "definitions"=>{
        "QueryInputElement"=>{"type"=>"object", "properties"=>{"key"=>{"type"=>"string"}, "value"=>{"type"=>"string"}}},
        "QueryInput"=>{"type"=>"object", "properties"=>{"elements"=>{"type"=>"array", "items"=>{"$ref"=>"#/definitions/QueryInputElement"}}}},
        "Thing"=>{"properties"=>{"id"=>{"type"=>"integer"}, "text"=>{"type"=>"string"}, "links"=>{"type"=>"link"}, "others"=>{"type"=>"text"}}},
        "ApiError"=>{"type"=>"object", "properties"=>{"code"=>{"type"=>"integer"}, "message"=>{"type"=>"string"}}},
        "Something"=>{"type"=>"object", "properties"=>{"id"=>{"type"=>"integer"}, "text"=>{"type"=>"string"}, "links"=>{"type"=>"link"}, "others"=>{"type"=>"text"}}}
    }}
  end

  let(:http_verbs) { %w[get post put delete]}
end

def mounted_paths
  %w[ /thing /other_thing /dummy ]
end
