require 'spec_helper'

describe "Form Params" do

  before :all do
    class FormParamApi < Grape::API
      format :json

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
      "swaggerVersion" => "1.1",
      "basePath" => "http://example.org",
      "resourcePath" => "",
      "apis" => [
        {
          "path" => "/items.{format}",
          "operations" => [
            {
              "notes" => nil,
              "summary" => "",
              "nickname" => "POST-items---format-",
              "httpMethod" => "POST",
              "parameters" => [ { "paramType" => "form", "name" => "name", "description" => "name of item", "dataType" => "String", "required" => true } ]
            }
          ]
        },
        {
          "path" => "/items/{id}.{format}",
          "operations" => [
            {
              "notes" => nil,
              "summary" => "",
              "nickname" => "PUT-items--id---format-",
              "httpMethod" => "PUT",
              "parameters" => [ { "paramType" => "path", "name" => "id", "description" => "id of item", "dataType" => "Integer", "required" => true },
                                { "paramType" => "form", "name" => "name", "description" => "name of item", "dataType" => "String", "required" => true} ]
            }
          ]
        },
        {
          "path" => "/items/{id}.{format}",
          "operations" => [
            {
              "notes" => nil,
              "summary" => "",
              "nickname" => "PATCH-items--id---format-",
              "httpMethod" => "PATCH",
              "parameters" => [ { "paramType" => "path", "name" => "id", "description" => "id of item", "dataType" => "Integer", "required" => true },
                                { "paramType" => "form", "name" => "name", "description" => "name of item", "dataType" => "String", "required" => true } ]
            }
          ]
        }
      ]
    }
  end

end
