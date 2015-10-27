require 'spec_helper'

describe 'a simple mounted api' do
  before :all do
    class CustomType; end

    class SimpleMountedApi < Grape::API
      desc 'Document root'
      get do
      end

      desc 'This gets something.',
           notes: '_test_'

      get '/simple' do
        { bla: 'something' }
      end

      desc 'This gets something for URL using - separator.',
           notes: '_test_'

      get '/simple-test' do
        { bla: 'something' }
      end

      desc 'this gets something else',
           headers: {
             'XAuthToken' => { description: 'A required header.', required: true },
             'XOtherHeader' => { description: 'An optional header.', required: false }
           },
           http_codes: [
             { code: 403, message: 'invalid pony' },
             { code: 405, message: 'no ponies left!' }
           ]

      get '/simple_with_headers' do
        { bla: 'something_else' }
      end

      desc 'this takes an array of parameters',
           params: {
             'items[]' => { description: 'array of items' }
           }

      post '/items' do
        {}
      end

      desc 'this uses a custom parameter',
           params: {
             'custom' => { type: CustomType, description: 'array of items' }
           }

      get '/custom' do
        {}
      end
    end

    class SimpleApi < Grape::API
      mount SimpleMountedApi
      add_swagger_documentation
    end
  end

  def app
    SimpleApi
  end

  it 'retrieves swagger-documentation on /swagger_doc' do
    get '/swagger_doc.json'
    expect(JSON.parse(last_response.body)).to eq(
      {
        "info"=>{"title"=>"API title", "version"=>"v1"},
        "swagger"=>"2.0",
        "produces"=>["application/xml", "application/json", "application/octet-stream", "text/plain"],
        "host"=>"example.org",
        "paths"=>
        {"/simple"=>{"get"=>{"produces"=>["application/json"], "responses"=>{"200"=>{"description"=>"This gets something.", "schema"=>{"$ref"=>"#/definitions/Simple"}}}}},
         "/simple-test"=>{"get"=>{"produces"=>["application/json"], "responses"=>{"200"=>{"description"=>"This gets something for URL using - separator.", "schema"=>{"$ref"=>"#/definitions/SimpleTest"}}}}},
         "/simple_with_headers"=>
          {"get"=>
            {"produces"=>["application/json"],
             "responses"=>
              {"200"=>{"description"=>"this gets something else", "schema"=>{"$ref"=>"#/definitions/SimpleWithHeader"}},
               "403"=>{"description"=>"invalid pony", "schema"=>{"$ref"=>"#/definitions/SimpleWithHeader"}},
               "405"=>{"description"=>"no ponies left!", "schema"=>{"$ref"=>"#/definitions/SimpleWithHeader"}}}}},
         "/items"=>{"post"=>{"produces"=>["application/json"], "responses"=>{"201"=>{"description"=>"this takes an array of parameters", "schema"=>{"$ref"=>"#/definitions/Item"}}}, "parameters"=>[]}},
         "/custom"=>{"get"=>{"produces"=>["application/json"], "responses"=>{"200"=>{"description"=>"this uses a custom parameter", "schema"=>{"$ref"=>"#/definitions/Custom"}}}, "parameters"=>[]}}},
        "definitions"=>{}}
    )
  end

  it 'retrieves the documentation for mounted-api' do
    get '/swagger_doc/simple.json'
    expect(JSON.parse(last_response.body)).to eq({
      "info"=>{"title"=>"API title", "version"=>"v1"},
      "swagger"=>"2.0",
      "produces"=>["application/xml", "application/json", "application/octet-stream", "text/plain"],
      "host"=>"example.org",
      "paths"=>{"/simple"=>{"get"=>{"produces"=>["application/json"], "responses"=>{"200"=>{"description"=>"This gets something.", "schema"=>{"$ref"=>"#/definitions/Simple"}}}}}},
      "definitions"=>{}})
  end

  context 'retrieves the documentation for mounted-api that' do
    it "contains '-' in URL" do
      get '/swagger_doc/simple-test.json'
      expect(JSON.parse(last_response.body)).to eq({
        "info"=>{"title"=>"API title", "version"=>"v1"},
        "swagger"=>"2.0",
        "produces"=>["application/xml", "application/json", "application/octet-stream", "text/plain"],
        "host"=>"example.org",
        "paths"=>{
          "/simple-test"=>{"get"=>{
            "produces"=>["application/json"],
            "responses"=>{
              "200"=>{"description"=>"This gets something for URL using - separator.",
                "schema"=>{"$ref"=>"#/definitions/SimpleTest"}}}}}},
                "definitions"=>{}}
        )
    end

    it 'includes headers' do
      get '/swagger_doc/simple_with_headers.json'
      expect(JSON.parse(last_response.body)['paths']).to eq(
      {"/simple_with_headers"=>
        {"get"=>
          {"produces"=>["application/json"],
           "responses"=>
            {"200"=>{"description"=>"this gets something else", "schema"=>{"$ref"=>"#/definitions/SimpleWithHeader"}},
             "403"=>{"description"=>"invalid pony", "schema"=>{"$ref"=>"#/definitions/SimpleWithHeader"}},
             "405"=>{"description"=>"no ponies left!", "schema"=>{"$ref"=>"#/definitions/SimpleWithHeader"}}}}}}
      )
    end

    it 'supports multiple parameters' do
      get '/swagger_doc/items.json'
      expect(JSON.parse(last_response.body)['paths']).to eq(
        {
          "/items"=>{
            "post"=>{
              "produces"=>["application/json"],
              "responses"=>{
                "201"=>{
                  "description"=>"this takes an array of parameters",
                  "schema"=>{
                    "$ref"=>"#/definitions/Item"}
              }},
              "parameters"=>[]}}}
        )
    end

    it 'supports custom types' do
      get '/swagger_doc/custom.json'
      expect(JSON.parse(last_response.body)['paths']).to eq(
        {
          "/custom"=>{
            "get"=>{
              "produces"=>["application/json"],
              "responses"=>{
                "200"=>{
                  "description"=>"this uses a custom parameter",
                  "schema"=>{"$ref"=>"#/definitions/Custom"}}},
              "parameters"=>[]}}}
      )
    end
  end
end
