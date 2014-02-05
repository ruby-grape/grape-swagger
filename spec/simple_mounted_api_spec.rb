require 'spec_helper'

describe "a simple mounted api" do
  before :all do
    class CustomType; end

    class SimpleMountedApi < Grape::API
      desc "Document root"
      get do
      end

      desc 'This gets something.', {
        :notes => '_test_'
      }

      get '/simple' do
        { bla: 'something' }
      end

      desc 'This gets something for URL using - separator.', {
        :notes => '_test_'
      }

      get '/simple-test' do
        { bla: 'something' }
      end

      desc 'this gets something else', {
        :headers => {
          "XAuthToken" => { description: "A required header.", required: true },
          "XOtherHeader" => { description: "An optional header.", required: false }
        },
        :http_codes => {
          403 => "invalid pony",
          405 => "no ponies left!"
        }
      }
      get '/simple_with_headers' do
        {:bla => 'something_else'}
      end

      desc 'this takes an array of parameters', {
        :params => {
          "items[]" => { description: "array of items" }
        }
      }
      post '/items' do
        {}
      end

      desc 'this uses a custom parameter', {
        :params => {
          "custom" => { type: CustomType, description: "array of items" }
        }
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

  def app; SimpleApi end

  it "retrieves swagger-documentation on /swagger_doc" do
    get '/swagger_doc.json'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.2",
      "basePath" => "http://example.org",
      "info" => {},
      "produces" => ["application/xml", "application/json", "text/plain"],
      "operations" => [],
      "apis" => [
        { "path" => "/swagger_doc/simple.{format}" },
        { "path" => "/swagger_doc/simple-test.{format}" },
        { "path" => "/swagger_doc/simple_with_headers.{format}" },
        { "path" => "/swagger_doc/items.{format}" },
        { "path" => "/swagger_doc/custom.{format}" },
        { "path" => "/swagger_doc/swagger_doc.{format}" }
      ]
    }
  end

  it "retrieves the documentation for mounted-api" do
    get '/swagger_doc/simple.json'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.2",
      "basePath" => "http://example.org",
      "resourcePath" => "",
      "apis" => [{
        "path" => "/simple.{format}",
        "operations" => [{
          "produces" => ["application/xml", "application/json", "text/plain"],
          "notes" => "_test_",
          "summary" => "This gets something.",
          "nickname" => "GET-simple---format-",
          "httpMethod" => "GET",
          "parameters" => []
        }]
      }]
    }
  end

  context "retrieves the documentation for mounted-api that" do
    it "contains '-' in URL" do
      get '/swagger_doc/simple-test.json'
      JSON.parse(last_response.body).should == {
        "apiVersion" => "0.1",
        "swaggerVersion" => "1.2",
        "basePath" => "http://example.org",
        "resourcePath" => "",
        "apis" => [{
          "path" => "/simple-test.{format}",
          "operations" => [{
            "produces" => ["application/xml", "application/json", "text/plain"],
            "notes" => "_test_",
            "summary" => "This gets something for URL using - separator.",
            "nickname" => "GET-simple-test---format-",
            "httpMethod" => "GET",
            "parameters" => []
          }]
        }]
      }
    end

    it "includes headers" do
      get '/swagger_doc/simple_with_headers.json'
      JSON.parse(last_response.body)["apis"].should == [{
        "path" => "/simple_with_headers.{format}",
        "operations" => [{
          "produces" => ["application/xml", "application/json", "text/plain"],
          "notes" => nil,
          "notes" => "",
          "summary" => "this gets something else",
          "nickname" => "GET-simple_with_headers---format-",
          "httpMethod" => "GET",
          "parameters" => [
            { "paramType" => "header", "name" => "XAuthToken", "description" => "A required header.", "type" => "String", "dataType" => "String", "required" => true },
            { "paramType" => "header", "name" => "XOtherHeader", "description" => "An optional header.", "type" => "String", "dataType" => "String", "required" => false }
          ],
          "responseMessages" => [
            { "code" => 403, "message" => "invalid pony" },
            { "code" => 405, "message" => "no ponies left!" }
          ]
        }]
      }]
    end

    it "supports multiple parameters" do
      get '/swagger_doc/items.json'
      JSON.parse(last_response.body)["apis"].should == [{
        "path" => "/items.{format}",
        "operations" => [{
          "produces" => ["application/xml", "application/json", "text/plain"],
          "notes" => nil,
          "notes" => "",
          "summary" => "this takes an array of parameters",
          "nickname" => "POST-items---format-",
          "httpMethod" => "POST",
          "parameters" => [ { "paramType" => "form", "name" => "items[]", "description" => "array of items", "type" => "String", "dataType" => "String", "required" => false } ]
        }]
      }]
    end

    it "supports custom types" do
      get '/swagger_doc/custom.json'
      JSON.parse(last_response.body)["apis"].should == [{
        "path" => "/custom.{format}",
        "operations" => [{
          "produces" => ["application/xml", "application/json", "text/plain"],
          "notes" => nil,
          "notes" => "",
          "summary" => "this uses a custom parameter",
          "nickname" => "GET-custom---format-",
          "httpMethod" => "GET",
          "parameters" => [ { "paramType" => "query", "name" => "custom", "description" => "array of items", "type" => "CustomType", "dataType" => "CustomType", "required" => false } ]
        }]
      }]
    end

  end

end
