require 'spec_helper'

describe "an API with hidden entity attributes" do
  before :all do
    module Entities
      class Item < Grape::Entity
        expose :id, documentation: { type: 'string', desc: 'The item ID' }
        expose :secret_name, documentation: { type: 'string', hidden: true, desc: 'A super secret name of the item' }
      end
    end

    class HideEntityAttributeApi < Grape::API

      desc 'Add an item', {
        entity: Entities::Item
      }
      post '/items' do
        {}
      end

      add_swagger_documentation \
        override_hidden: -> (req) { true }
    end
  end

  def app; HideEntityAttributeApi end

  it "retrieves swagger-documentation that does include hidden attributes in entities" do
    get '/swagger_doc/items.json'
    JSON.parse(last_response.body).should ==  {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.2",
      "resourcePath" => "",
      "apis" => [{
        "path" => "/items.{format}",
        "operations" => [{
          "produces" => ["application/xml", "application/json", "application/octet-stream", "text/plain"],
          "notes" => "",
          "summary" => "Add an item",
          "nickname" => "POST-items---format-",
          "httpMethod" => "POST",
          "parameters" => [],
          "type" => "Item"
        }]
      }],
      "basePath" => "http://example.org",
      "models" => {
        "Item" => {
          "id" => "Item",
          "name" => "Item",
          "properties" => {
            "id" => {
              "type" => "string",
              "description" => "The item ID"
            },
            "secret_name" => {
              "type" => "string",
              "hidden" => true,
              "description" => "A super secret name of the item"
            }
          }
        }
      }
    }
  end
end
