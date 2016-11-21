require 'spec_helper'

describe "a hide mounted api with hide override set" do
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
      add_swagger_documentation \
        override_hidden: -> (req) { true }
    end
  end

  def app; HideApi end

  it "retrieves swagger-documentation that includes hidden endpoints" do
    get '/swagger_doc.json'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.2",
      "basePath" => "http://example.org",
      "info" => {},
      "produces" => ["application/xml", "application/json", "application/octet-stream", "text/plain"],
      "operations" => [],
      "apis" => [
        { "path" => "/swagger_doc/simple.{format}" },
        { "path" => "/swagger_doc/hide.{format}" },
        { "path" => "/swagger_doc/swagger_doc.{format}" }
      ]
    }
  end
end


describe "a hide mounted api with same namespace with hide override set" do
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
      add_swagger_documentation \
        override_hidden: -> (req) { true }
    end
  end

  def app; HideNamespaceApi end

  it "retrieves swagger-documentation on /swagger_doc" do
    get '/swagger_doc.json'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.2",
      "basePath" => "http://example.org",
      "info" => {},
      "produces" => ["application/xml", "application/json", "application/octet-stream", "text/plain"],
      "operations" => [],
      "apis" => [
        { "path" => "/swagger_doc/simple.{format}" },
        { "path" => "/swagger_doc/swagger_doc.{format}" }
      ]
    }
  end

  it "retrieves the documentation for mounted-api that does include hidden endpoints" do
    get '/swagger_doc/simple.json'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.2",
      "basePath" => "http://example.org",
      "resourcePath" => "",
      "apis" => [{
        "path" => "/simple/show.{format}",
        "operations" => [{
          "produces" => ["application/xml", "application/json", "application/octet-stream", "text/plain"],
          "notes" => nil,
          "notes" => "",
          "summary" => "Show this endpoint",
          "nickname" => "GET-simple-show---format-",
          "httpMethod" => "GET",
          "parameters" => []
        }]
      },
      {
        "path" => "/simple/hide.{format}",
        "operations" => [{
          "produces" => ["application/xml", "application/json", "application/octet-stream", "text/plain"],
          "notes" => nil,
          "notes" => "",
          "summary" => "Hide this endpoint",
          "nickname" => "GET-simple-hide---format-",
          "httpMethod" => "GET",
          "parameters" => []
        }]
      }]
    }
  end
end
