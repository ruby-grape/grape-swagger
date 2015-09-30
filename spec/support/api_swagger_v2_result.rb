RSpec.shared_context "swagger example" do
  let(:swagger_json) do
    {"info"=>
      {"title"=>"The API title to be displayed on the API homepage.",
       "description"=>"A description of the API.",
       "termsOfServiceUrl"=>"www.The-URL-of-the-terms-and-service.com",
       "contact"=>{"contact_name"=>"Contact name", "contact_email"=>"Contact@email.com", "contact_url"=>"Contact URL"},
       "license"=>{"name"=>"The name of the license.", "url"=>"www.The-URL-of-the-license.org"},
       "version"=>"v1"},
      "swagger"=>"2.0",
      "produces"=>["application/json"],
      "host"=>"example.org",
      "basePath"=>"",
      "paths"=>
      {"/otherthing/{elements}"=>
        {"get"=>
          {"produces"=>["application/json"],
           "responses"=>{"200"=>{"description"=>"get Otherthing(s)", "schema"=>{"$ref"=>"#/definitions/Otherthing"}}},
           "parameters"=>[{"in"=>"array", "name"=>"elements", "description"=>"Set of configuration", "type"=>"string", "required"=>true, "allowMultiple"=>true}]}},
       "/thing"=>
        {"get"=>
          {"produces"=>["application/json"],
           "responses"=>
            {"200"=>{"description"=>"get Thing(s)", "schema"=>{"$ref"=>"#/definitions/Thing"}}, "401"=>{"description"=>"Unauthorized", "schema"=>{"$ref"=>"#/definitions/ApiError"}}},
           "parameters"=>[]},
         "post"=>
          {"produces"=>["application/json"],
           "responses"=>
            {"201"=>{"description"=>"created Thing", "schema"=>{"$ref"=>"#/definitions/Thing"}},
             "422"=>{"description"=>"Unprocessible Entity", "schema"=>{"$ref"=>"#/definitions/Thing"}}},
           "parameters"=>
            [{"in"=>"formData", "name"=>"text", "description"=>"Content of something.", "type"=>"string", "required"=>true, "allowMultiple"=>false},
             {"in"=>"body", "name"=>"links", "description"=>nil, "type"=>"Array", "required"=>true, "allowMultiple"=>true}]}},
       "/thing/{id}"=>
        {"get"=>
          {"produces"=>["application/json"],
           "responses"=>
            {"200"=>{"description"=>"getting a single thing", "schema"=>{"$ref"=>"#/definitions/Thing"}},
             "401"=>{"description"=>"Unauthorized", "schema"=>{"$ref"=>"#/definitions/Thing"}}},
           "parameters"=>[{"in"=>"path", "name"=>"id", "description"=>nil, "type"=>"integer", "required"=>true, "allowMultiple"=>false, "format"=>"int32"}]},
         "put"=>
          {"produces"=>["application/json"],
           "responses"=>{"200"=>{"description"=>"updated Thing", "schema"=>{"$ref"=>"#/definitions/Thing"}}},
           "parameters"=>
            [{"in"=>"path", "name"=>"id", "description"=>nil, "type"=>"integer", "required"=>true, "allowMultiple"=>false, "format"=>"int32"},
             {"in"=>"formData", "name"=>"text", "description"=>"Content of something.", "type"=>"string", "required"=>false, "allowMultiple"=>false},
             {"in"=>"body", "name"=>"links", "description"=>nil, "type"=>"Array", "required"=>false, "allowMultiple"=>true}]},
         "delete"=>
          {"produces"=>["application/json"],
           "responses"=>{"200"=>{"description"=>"deleted Thing", "schema"=>{"$ref"=>"#/definitions/Thing"}}},
           "parameters"=>[{"in"=>"path", "name"=>"id", "description"=>nil, "type"=>"integer", "required"=>true, "allowMultiple"=>false, "format"=>"int32"}]}},
       "/thing2"=>
        {"get"=>
          {"produces"=>["application/json"],
           "responses"=>
            {"200"=>{"description"=>"get Horses", "schema"=>{"$ref"=>"#/definitions/EnumValues"}},
             "401"=>{"description"=>"HorsesOutError", "schema"=>{"$ref"=>"#/definitions/ApiError"}}},
           "parameters"=>[]}}},
      "definitions"=>
      {"Otherthing"=>{"properties"=>{"elements"=>{"type"=>"QueryInputElement"}}},
       "ApiError"=>{"properties"=>{"code"=>{"type"=>"integer"}, "message"=>{"type"=>"string"}}},
       "Thing"=>{"properties"=>{"id"=>{"type"=>"integer"}, "text"=>{"type"=>"string"}, "links"=>{"type"=>"link"}, "others"=>{"type"=>"text"}}},
       "EnumValues"=>{"properties"=>{"gender"=>{"type"=>"string", "enum"=>["Male", "Female"]}, "number"=>{"type"=>"integer", "enum"=>[1, 2]}}},
       "Thing2"=>{"properties"=>{"id"=>{"type"=>"integer"}, "text"=>{"type"=>"string"}, "links"=>{"type"=>"link"}, "others"=>{"type"=>"text"}}}}}
  end

  let(:http_verbs) { %w[get post put delete]}
end
