require 'spec_helper'

describe "API Models" do

  before :all do
    module Entities
      class Something < Grape::Entity
        expose :text, :documentation => { :type => "string", :desc => "Content of something." }
      end
    end

    module Entities
      module Some
        class Thing < Grape::Entity
          expose :text, :documentation => { :type => "string", :desc => "Content of something." }
        end
      end
    end

    class ModelsApi < Grape::API
      format :json
      desc 'This gets something.', {
        entity: Entities::Something
      }
      get '/something' do
        something = OpenStruct.new text: 'something'
        present something, with: Entities::Something
      end

      desc 'This gets thing.', {
        entity: Entities::Some::Thing
      }
      get "/thing" do
        thing = OpenStruct.new text: 'thing'
        present thing, with: Entities::Some::Thing
      end
      add_swagger_documentation
    end
  end

  def app; ModelsApi; end

  it "should document specified models" do
    get '/swagger_doc'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.2",
      "basePath" => "http://example.org",
      "info" => {},
      "produces" => ["application/json"],
      "operations" => [],
      "apis" => [
        { "path" => "/swagger_doc/something.{format}" },
        { "path" => "/swagger_doc/thing.{format}" },
        { "path" => "/swagger_doc/swagger_doc.{format}" }
      ]
    }
  end

  it "should include type when specified" do
    get '/swagger_doc/something.json'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.2",
      "basePath" => "http://example.org",
      "resourcePath" => "",
      "apis" => [{
        "path" => "/something.{format}",
        "operations" => [{
          "produces" => [
            "application/json"
          ],
          "notes" => "",
          "type" => "Something",
          "summary" => "This gets something.",
          "nickname" => "GET-something---format-",
          "httpMethod" => "GET",
          "parameters" => []
        }]
      }],
      "models" => {
        "Something" => {
          "id" => "Something",
          "name" => "Something",
          "properties" => {
            "text" => {
              "type" => "string",
              "description" => "Content of something."
            }
          }
        }
      }
    }
  end

  it "should include nested type when specified" do
    get '/swagger_doc/thing.json'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.2",
      "basePath" => "http://example.org",
      "resourcePath" => "",
      "apis" => [{
        "path" => "/thing.{format}",
        "operations" => [{
          "produces" => [
            "application/json"
          ],
          "notes" => "",
          "type" => "Some::Thing",
          "summary" => "This gets thing.",
          "nickname" => "GET-thing---format-",
          "httpMethod" => "GET",
          "parameters" => []
        }]
      }],
      "models" => {
        "Some::Thing" => {
          "id" => "Some::Thing",
          "name" => "Some::Thing",
          "properties" => {
            "text" => {
              "type" => "string",
              "description" => "Content of something."
            }
          }
        }
      }
    }
  end

end
