require 'spec_helper'

describe 'a simple mounted api' do
  before :all do
    class CustomType; end

    class NamespacedApi < Grape::API
      namespace :hudson do
        desc 'Document root'
        get '/' do
        end
      end

      namespace :colorado do
        desc 'This gets something.',
          notes: '_test_'

        get '/simple' do
          { bla: 'something' }
        end
      end

      namespace :colorado do
        desc 'This gets something for URL using - separator.',
          notes: '_test_'

        get '/simple-test' do
          { bla: 'something' }
        end
      end

      namespace :thames do
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
      end

      namespace :niles do
        desc 'this takes an array of parameters',
          params: {
            'items[]' => { description: 'array of items', is_array: true }
          }

        post '/items' do
          {}
        end
      end

      namespace :niles do
        desc 'this uses a custom parameter',
          params: {
            'custom' => { type: CustomType, description: 'array of items', is_array: true }
          }

        get '/custom' do
          {}
        end
      end
    end

    class NamespaceApi < Grape::API
      mount NamespacedApi
      add_swagger_documentation
    end
  end

  def app
    NamespaceApi
  end

  describe "retrieves swagger-documentation on /swagger_doc" do
    subject do
      get '/swagger_doc.json'
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
        "paths" => {
          "/hudson"=>{"get"=>{"produces"=>["application/json"], 
            "tags"=>["hudson"], 
            "responses"=>{"200"=>{"description"=>"Document root"}}}}, 
          "/colorado/simple"=>{"get"=>{"produces"=>["application/json"], 
            "tags"=>["colorado"], 
            "responses"=>{"200"=>{"description"=>"This gets something."}}}}, 
          "/colorado/simple-test"=>{"get"=>{"produces"=>["application/json"], 
            "tags"=>["colorado"], 
            "responses"=>{"200"=>{"description"=>"This gets something for URL using - separator."}}}}, 
          "/thames/simple_with_headers"=>{"get"=>{"headers"=>{"XAuthToken"=>{"description"=>"A required header.", "required"=>true}, "XOtherHeader"=>{"description"=>"An optional header.", "required"=>false}}, "produces"=>["application/json"], 
            "tags"=>["thames"], 
            "responses"=>{"200"=>{"description"=>"this gets something else"}, "403"=>{"description"=>"invalid pony"}, "405"=>{"description"=>"no ponies left!"}}}}, 
          "/niles/items"=>{"post"=>{"produces"=>["application/json"], "parameters"=>[{"in"=>"formData", "name"=>"items[]", "description"=>"array of items", "type"=>"string", "required"=>false, "allowMultiple"=>true}], 
            "tags"=>["niles"], 
            "responses"=>{"201"=>{"description"=>"this takes an array of parameters"}}}}, 
          "/niles/custom"=>{"get"=>{"produces"=>["application/json"], "parameters"=>[{"in"=>"query", "name"=>"custom", "description"=>"array of items", "type"=>"CustomType", "required"=>false, "allowMultiple"=>true}], 
            "tags"=>["niles"], 
            "responses"=>{"200"=>{"description"=>"this uses a custom parameter"}}}}}})
    end
  end

  describe 'retrieves the documentation for mounted-api' do
    subject do
      get '/swagger_doc/colorado.json'
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
          "/colorado/simple"=>{
              "get"=>{"produces"=>["application/json"], 
              "tags"=>["colorado"], 
              "responses"=>{"200"=>{"description"=>"This gets something."}}}}, 
          "/colorado/simple-test"=>{
              "get"=>{"produces"=>["application/json"], 
              "tags"=>["colorado"], 
              "responses"=>{"200"=>{"description"=>"This gets something for URL using - separator."}}}}
        }})
    end

    describe 'includes headers' do
      subject do
        get '/swagger_doc/thames.json'
        JSON.parse(last_response.body)
      end

      specify do
        expect(subject['paths']).to eq({
          "/thames/simple_with_headers"=>{
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
