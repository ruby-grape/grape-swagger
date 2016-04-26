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
        "contact"=>{"name"=>"Contact name", "email"=>"Contact@email.com", "url"=>"Contact URL"},
        "license"=>{"name"=>"The name of the license.", "url"=>"www.The-URL-of-the-license.org"},
        "version"=>"v1"
      },
      "swagger"=>"2.0",
      "produces"=>["application/json"],
      "host"=>"example.org",
      "basePath"=>"/api",
      "tags"=>[
        {"name"=>"other_thing", "description"=>"Operations about other_things"},
        {"name"=>"thing", "description"=>"Operations about things"},
        {"name"=>"thing2", "description"=>"Operations about thing2s"},
        {"name"=>"dummy", "description"=>"Operations about dummies"}
      ],
      "paths"=>{
        "/v3/other_thing/{elements}"=>{
          "get"=>{
            "description"=>"nested route inside namespace",
            "produces"=>["application/json"],
            "parameters"=>[{"in"=>"body", "name"=>"elements", "description"=>"Set of configuration", "type"=>"array", "items"=>{"type"=>"string"}, "required"=>true}],
            "responses"=>{"200"=>{"description"=>"nested route inside namespace", "schema"=>{"$ref"=>"#/definitions/QueryInput"}}},
            "tags"=>["other_thing"],
            "operationId"=>"getV3OtherThingElements",
            "x-amazon-apigateway-auth"=>{"type"=>"none"},
            "x-amazon-apigateway-integration"=>{"type"=>"aws", "uri"=>"foo_bar_uri", "httpMethod"=>"get"}
        }},
        "/thing"=>{
          "get"=>{
            "description"=>"This gets Things.",
            "produces"=>["application/json"],
            "parameters"=>[
              {"in"=>"query", "name"=>"id", "description"=>"Identity of Something", "type"=>"integer", "format"=>"int32", "required"=>false},
              {"in"=>"query", "name"=>"text", "description"=>"Content of something.", "type"=>"string", "required"=>false},
              {"in"=>"formData", "name"=>"links", "type"=>"array", "items"=>{"type"=>"link"}, "required"=>false},
              {"in"=>"query", "name"=>"others", "type"=>"text", "required"=>false}
            ],
            "responses"=>{"200"=>{"description"=>"This gets Things."}, "401"=>{"description"=>"Unauthorized", "schema"=>{"$ref"=>"#/definitions/ApiError"}}},
            "tags"=>["thing"],
            "operationId"=>"getThing"
          },
          "post"=>{
            "description"=>"This creates Thing.",
            "produces"=>["application/json"],
            "consumes"=>["application/json"],
            "parameters"=>[
              {"in"=>"formData", "name"=>"text", "description"=>"Content of something.", "type"=>"string", "required"=>true},
              {"in"=>"formData", "name"=>"links", "type"=>"array", "items"=>{"type"=>"string"}, "required"=>true}
            ],
            "responses"=>{"201"=>{"description"=>"This creates Thing.", "schema"=>{"$ref"=>"#/definitions/Something"}}, "422"=>{"description"=>"Unprocessible Entity"}},
            "tags"=>["thing"],
            "operationId"=>"postThing"
        }},
        "/thing/{id}"=>{
          "get"=>{
            "description"=>"This gets Thing.",
            "produces"=>["application/json"],
            "parameters"=>[{"in"=>"path", "name"=>"id", "type"=>"integer", "format"=>"int32", "required"=>true}],
            "responses"=>{"200"=>{"description"=>"getting a single thing"}, "401"=>{"description"=>"Unauthorized"}},
            "tags"=>["thing"],
            "operationId"=>"getThingId"
          },
          "put"=>{
            "description"=>"This updates Thing.",
            "produces"=>["application/json"],
            "consumes"=>["application/json"],
            "parameters"=>[
              {"in"=>"path", "name"=>"id", "type"=>"integer", "format"=>"int32", "required"=>true},
              {"in"=>"formData", "name"=>"text", "description"=>"Content of something.", "type"=>"string", "required"=>false},
              {"in"=>"formData", "name"=>"links", "type"=>"array", "items"=>{"type"=>"string"}, "required"=>false}
            ],
            "responses"=>{"200"=>{"description"=>"This updates Thing.", "schema"=>{"$ref"=>"#/definitions/Something"}}},
            "tags"=>["thing"],
            "operationId"=>"putThingId"
          },
          "delete"=>{
            "description"=>"This deletes Thing.",
            "produces"=>["application/json"],
            "parameters"=>[{"in"=>"path", "name"=>"id", "type"=>"integer", "format"=>"int32", "required"=>true}],
            "responses"=>{"200"=>{"description"=>"This deletes Thing.", "schema"=>{"$ref"=>"#/definitions/Something"}}},
            "tags"=>["thing"],
            "operationId"=>"deleteThingId"
        }},
        "/thing2"=>{
          "get"=>{
            "description"=>"This gets Things.",
            "produces"=>["application/json"],
            "responses"=>{"200"=>{"description"=>"get Horses", "schema"=>{"$ref"=>"#/definitions/Something"}}, "401"=>{"description"=>"HorsesOutError", "schema"=>{"$ref"=>"#/definitions/ApiError"}}},
            "tags"=>["thing2"],
            "operationId"=>"getThing2"
        }},
        "/dummy/{id}"=>{
          "delete"=>{
            "description"=>"dummy route.",
            "produces"=>["application/json"],
            "parameters"=>[{"in"=>"path", "name"=>"id", "type"=>"integer", "format"=>"int32", "required"=>true}],
            "responses"=>{"204"=>{"description"=>"dummy route."}, "401"=>{"description"=>"Unauthorized"}},
            "tags"=>["dummy"],
            "operationId"=>"deleteDummyId"
      }}},
      "definitions"=>{
        "QueryInput"=>{
          "type"=>"object",
          "properties"=>{"elements"=>{"type"=>"array", "items"=>{"$ref"=>"#/definitions/QueryInputElement"}, "description"=>"Set of configuration"}},
          "description"=>"nested route inside namespace"
        },
        "QueryInputElement"=>{
          "type"=>"object",
          "properties"=>{"key"=>{"type"=>"string", "description"=>"Name of parameter"}, "value"=>{"type"=>"string", "description"=>"Value of parameter"}}
        },
        "ApiError"=>{
          "type"=>"object",
          "properties"=>{"code"=>{"type"=>"integer", "format"=>"int32", "description"=>"status code"}, "message"=>{"type"=>"string", "description"=>"error message"}},
          "description"=>"This gets Things."
        },
        "Something"=>{
          "type"=>"object",
          "properties"=>{
            "id"=>{"type"=>"integer", "format"=>"int32", "description"=>"Identity of Something"},
            "text"=>{"type"=>"string", "description"=>"Content of something."},
            "links"=>{"type"=>"link"},
            "others"=>{"type"=>"text"}
          },
          "description"=>"This gets Things."
    }}}
  end

  let(:http_verbs) { %w[get post put delete]}
end

def mounted_paths
  %w[ /thing /other_thing /dummy ]
end
