require 'spec_helper'

describe 'namespace tags check while using prefix and version' do
  include_context "namespace example"

  before :all do
    module TheApi
      class NamespaceApi < Grape::API
        version :v1
      end
    end

    class TagApi < Grape::API
      prefix :api
      mount TheApi::NamespaceApi
      add_swagger_documentation version: 'v1'
    end
  end

  def app
    TagApi
  end

  describe "retrieves swagger-documentation on /swagger_doc" do
    subject do
      get '/api/swagger_doc.json'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject).to eq({
        "info"=>{"title"=>"API title", "version"=>"v1"},
        "swagger"=>"2.0",
        "produces" => ["application/xml", "application/json", "application/octet-stream", "text/plain"],
        "host"=>"example.org",
        "tags"=>[{"name"=>"hudson", "description"=>"Operations about hudsons"},
          {"name"=>"colorado", "description"=>"Operations about colorados"},
          {"name"=>"thames", "description"=>"Operations about thames"},
          {"name"=>"niles", "description"=>"Operations about niles"}],
        "schemes"=>["https", "http"],
        "paths"=>{
          "/api/v1/hudson"=>{"get"=>{"produces"=>["application/json"],
            "tags"=>["hudson"],
            "responses"=>{"200"=>{"description"=>"Document root"}}}},
          "/api/v1/colorado/simple"=>{"get"=>{"produces"=>["application/json"],
            "tags"=>["colorado"],
            "responses"=>{"200"=>{"description"=>"This gets something."}}}},
          "/api/v1/colorado/simple-test"=>{"get"=>{"produces"=>["application/json"],
            "tags"=>["colorado"],
            "responses"=>{"200"=>{"description"=>"This gets something for URL using - separator."}}}},
          "/api/v1/thames/simple_with_headers"=>{"get"=>{"headers"=>{"XAuthToken"=>{"description"=>"A required header.", "required"=>true}, "XOtherHeader"=>{"description"=>"An optional header.", "required"=>false}}, "produces"=>["application/json"],
            "tags"=>["thames"], "responses"=>{"200"=>{"description"=>"this gets something else"}, "403"=>{"description"=>"invalid pony"}, "405"=>{"description"=>"no ponies left!"}}}},
            "/api/v1/niles/items"=>{"post"=>{"produces"=>["application/json"], "parameters"=>[{"in"=>"formData", "name"=>"items[]", "description"=>"array of items", "type"=>"string", "required"=>false, "allowMultiple"=>true}],
            "tags"=>["niles"], "responses"=>{"201"=>{"description"=>"this takes an array of parameters"}}}},
          "/api/v1/niles/custom"=>{"get"=>{"produces"=>["application/json"], "parameters"=>[{"in"=>"query", "name"=>"custom", "description"=>"array of items", "type"=>"TheApi::CustomType", "required"=>false, "allowMultiple"=>true}],
            "tags"=>["niles"], "responses"=>{"200"=>{"description"=>"this uses a custom parameter"}}}}}})
    end
  end


  describe 'retrieves the documentation for mounted-api' do
    subject do
      get '/api/swagger_doc/colorado.json'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject).to eq({
        "info"=>{"title"=>"API title", "version"=>"v1"},
        "swagger"=>"2.0",
        "produces"=>["application/xml", "application/json", "application/octet-stream", "text/plain"],
        "host"=>"example.org",
        "tags"=>[{"name"=>"hudson", "description"=>"Operations about hudsons"}, {"name"=>"colorado", "description"=>"Operations about colorados"}, {"name"=>"thames", "description"=>"Operations about thames"}, {"name"=>"niles", "description"=>"Operations about niles"}],
        "schemes"=>["https", "http"],
        "paths"=>{
          "/api/v1/colorado/simple"=>{
              "get"=>{"produces"=>["application/json"],
              "tags"=>["colorado"],
              "responses"=>{"200"=>{"description"=>"This gets something."}}}},
          "/api/v1/colorado/simple-test"=>{
              "get"=>{"produces"=>["application/json"],
              "tags"=>["colorado"],
              "responses"=>{"200"=>{"description"=>"This gets something for URL using - separator."}}}}
        }})
    end

    describe 'includes headers' do
      subject do
        get '/api/swagger_doc/thames.json'
        JSON.parse(last_response.body)
      end

      specify do
        expect(subject['paths']).to eq({
          "/api/v1/thames/simple_with_headers"=>{
              "get"=>{
                  "headers"=>{
                    "XAuthToken"=>{"description"=>"A required header.", "required"=>true},
                    "XOtherHeader"=>{"description"=>"An optional header.", "required"=>false}},
                  "produces"=>["application/json"],
                  "tags"=>["thames"],
                  "responses"=>{
                      "200"=>{"description"=>"this gets something else"},
                      "403"=>{"description"=>"invalid pony"},
                      "405"=>{"description"=>"no ponies left!"}}}
          }})
      end
    end
  end
end
