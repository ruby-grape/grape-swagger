require 'spec_helper'

describe "Form Params" do

  before :all do
    class FormParamApi < Grape::API
      format :json
      content_type :json, 'application/json'

      params do
        requires :name, type: String, desc: "name of item"
      end
      post '/items' do
        {}
      end

      params do
        requires :id, type: Integer, desc: "id of item"
        requires :name, type: String, desc: "name of item"
      end
      put '/items/:id' do
        {}
      end

      params do
        requires :id, type: Integer, desc: "id of item"
        requires :name, type: String, desc: "name of item"
        group :media, type: Array do
          requires :url, type: String, desc: "url of item"
          optional :image_url, type: String, desc: "image url of item"
        end
      end
      patch '/items/:id' do
        {}
      end

      add_swagger_documentation
    end
  end

  def app; FormParamApi; end

  it "retrieves the documentation form params" do
    get '/swagger_doc/items.json'

    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.2",
      "resourcePath" => "",
      "basePath"=>"http://example.org",
      "apis" => [
        {
          "path" => "/items.{format}",
          "operations" => [
            {
              "produces" => ["application/json"],
              "notes" => "",
              "summary" => "",
              "nickname" => "POST-items---format-",
              "httpMethod" => "POST",
              "parameters" => [ { "paramType" => "form", "name" => "name", "description" => "name of item", "type" => "String", "dataType" => "String", "required" => true } ]
            }
          ]
        }, {
          "path" => "/items/{id}.{format}",
          "operations" => [
            {
              "produces" => ["application/json"],
              "notes" => "",
              "summary" => "",
              "nickname" => "PUT-items--id---format-",
              "httpMethod" => "PUT",
              "parameters" => [ { "paramType" => "path", "name" => "id", "description" => "id of item", "type" => "Integer", "dataType" => "Integer", "required" => true }, { "paramType" => "form", "name" => "name", "description" => "name of item", "type" => "String", "dataType" => "String", "required" => true } ]
            },
            {
              "produces" => ["application/json"],
              "notes" => "",
              "summary" => "",
              "nickname" => "PATCH-items--id---format-",
              "httpMethod" => "PATCH",
              "parameters" => [
                { "paramType" => "path", "name" => "id", "description" => "id of item", "type" => "Integer", "dataType" => "Integer", "required" => true },
                { "paramType" => "form", "name" => "name", "description" => "name of item", "type" => "String", "dataType" => "String", "required" => true },
                { "paramType" => "form", "name" => "media", "description" => nil, "type" => "Array", "dataType" => "Array", "required" => true },
                { "paramType" => "form", "name" => "media[url]", "description" => "url of item", "type" => "String", "dataType" => "String", "required" => false },
                { "paramType" => "form", "name" => "media[image_url]", "description" => "image url of item", "type" => "String", "dataType" => "String", "required" => false }
              ]
            }
          ]
        }
      ]
    }
  end
end
