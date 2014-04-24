require 'spec_helper'

describe "API Global Models" do

  before :all do
    module Entities
      module Some
        class Thing < Grape::Entity
          expose :text, :documentation => { :type => "string", :desc => "Content of something." }
        end
      end
    end

    class ModelsGlobalApi < Grape::API
      desc 'This gets thing.', {
        params: Entities::Some::Thing.documentation
      }
      get "/thing" do
        thing = OpenStruct.new text: 'thing'
        present thing, with: Entities::Some::Thing
      end

      add_swagger_documentation models:  [Entities::Some::Thing]
    end

  end

  def app; ModelsGlobalApi; end


  it "should include globals models specified" do
    get '/swagger_doc/thing.json'
    JSON.parse(last_response.body).should == {
      "apiVersion"=>"0.1",
      "swaggerVersion"=>"1.2",
      "resourcePath"=>"",
      "apis"=> [{
        "path"=>"/thing.{format}",
        "operations"=>[{
          "produces"=>["application/xml", "application/json", "text/plain"],
          "notes"=>"",
          "summary"=>"This gets thing.",
          "nickname"=>"GET-thing---format-",
          "httpMethod"=>"GET",
          "parameters"=>[{
            "paramType"=>"query",
            "name"=>"text",
            "description"=>"Content of something.",
            "type"=>"string",
            "dataType"=>"string",
            "required"=>false}]
          }]
        }],
        "basePath"=>"http://example.org",
        "models"=>{
          "Some::Thing"=>{
            "id"=>"Some::Thing",
            "name"=>"Some::Thing",
            "properties"=>{
              "text"=>{"type"=>"string", "description"=>"Content of something."}
            }
          }
        }
      }
  end
end
