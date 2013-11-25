require 'spec_helper'

describe "API Models" do

  before :all do
    module Entities
      class Something < Grape::Entity
        expose :text, :documentation => { :type => "string", :desc => "Content of something." }
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
      add_swagger_documentation
    end
  end

  def app; ModelsApi; end

  it "should document specified models" do
    get '/swagger_doc'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.1",
      "basePath" => "http://example.org",
      "info" => {},
      "operations" => [],
      "apis" => [
        { "path" => "/swagger_doc/something.{format}" },
        { "path" => "/swagger_doc/swagger_doc.{format}" }
      ]
    }
  end

  it "should include response_class when specified" do
    get '/swagger_doc/something.json'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.1",
      "basePath" => "http://example.org",
      "resourcePath" => "",
      "apis" => [
        { "path" => "/something.{format}",
          "operations" => [
            { "notes" => nil,
              "responseClass" => "Something",
              "summary" => "This gets something.",
              "nickname" => "GET-something---format-",
              "httpMethod" => "GET",
              "parameters" => []
            }
          ]
        }
      ],
      "models" => {
        "Something" => {
          "id" => "Something",
          "name" => "Something",
          "properties" => {
            "text" => {
              "type" => "string",
              "desc" => "Content of something."
            }
          }
        }
      }
    }
  end

end
