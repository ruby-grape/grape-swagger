require 'spec_helper'

describe "a hide mounted api" do
  before :all do
    class HideMountedApi < Grape::API
      desc 'Show this endpoint'
      get '/simple' do
        { :foo => 'bar' }
      end

      desc 'Hide this endpoint', {
        :hidden => true
      }
      get '/hide' do
        { :foo => 'bar' }
      end
    end

    class HideApi < Grape::API
      mount HideMountedApi
      add_swagger_documentation
    end
  end

  def app; HideApi end

  it "retrieves swagger-documentation that doesn't include hidden endpoints" do
    get '/swagger_doc.json'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.2",
      "info" => {},
      "produces" => ["application/xml", "application/json", "application/vnd.api+json", "text/plain"],
      "apis" => [
        { "path" => "/simple.{format}", "description" => "Operations about simples" },
        { "path" => "/swagger_doc.{format}", "description" => "Operations about swagger_docs" }
      ]
    }
  end
end


describe "a hide mounted api with same namespace" do
  before :all do
    class HideNamespaceMountedApi < Grape::API
      desc 'Show this endpoint'
      get '/simple/show' do
        { :foo => 'bar' }
      end

      desc 'Hide this endpoint', {
        :hidden => true
      }
      get '/simple/hide' do
        { :foo => 'bar' }
      end
    end

    class HideNamespaceApi < Grape::API
      mount HideNamespaceMountedApi
      add_swagger_documentation
    end
  end

  def app; HideNamespaceApi end

  it "retrieves swagger-documentation on /swagger_doc" do
    get '/swagger_doc.json'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.2",
      "info" => {},
      "produces" => ["application/xml", "application/json", "application/vnd.api+json", "text/plain"],
      "apis" => [
        { "path" => "/simple.{format}", "description" => "Operations about simples" },
        { "path" => "/swagger_doc.{format}", "description" => "Operations about swagger_docs" }
      ]
    }
  end

  it "retrieves the documentation for mounted-api that doesn't include hidden endpoints" do
    get '/swagger_doc/simple.json'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.2",
      "basePath" => "http://example.org",
      "resourcePath" => "/simple",
      "produces" => ["application/xml", "application/json", "application/vnd.api+json", "text/plain"],
      "apis" => [{
        "path" => "/simple/show.{format}",
        "operations" => [{
          "notes" => "",
          "summary" => "Show this endpoint",
          "nickname" => "GET-simple-show---format-",
          "method" => "GET",
          "parameters" => [],
          "type" => "void"
        }]
      }]
    }
  end
end
