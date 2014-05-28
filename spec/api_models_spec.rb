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
      "info" => {},
      "produces" => ["application/json"],
      "apis" => [
        { "path" => "/something.{format}", "description" => "Operations about somethings" },
        { "path" => "/thing.{format}", "description" => "Operations about things" },
        { "path" => "/swagger_doc.{format}", "description" => "Operations about swagger_docs" }
      ]
    }
  end

  it "should include type when specified" do
    get '/swagger_doc/something.json'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.2",
      "basePath" => "http://example.org",
      "resourcePath" => "/something",
      "produces" => [ "application/json" ],
      "apis" => [{
        "path" => "/something.{format}",
        "operations" => [{
          "notes" => "",
          "type" => "Something",
          "summary" => "This gets something.",
          "nickname" => "GET-something---format-",
          "method" => "GET",
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
      "resourcePath" => "/thing",
      "produces" => [ "application/json" ],
      "apis" => [{
        "path" => "/thing.{format}",
        "operations" => [{
          "notes" => "",
          "type" => "Some::Thing",
          "summary" => "This gets thing.",
          "nickname" => "GET-thing---format-",
          "method" => "GET",
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
