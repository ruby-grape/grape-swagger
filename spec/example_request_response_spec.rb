require 'spec_helper'

describe "Example Request and Response" do

  before :all do
    class DocumentationExampleApi < Grape::API
      format :json

      resource :somethings do
        desc 'This gets all somethings.', {
          documentation: {
            example_response: {
              code: 200,
              headers: { 'Content-Type' => 'application/json' },
              body: JSON.generate([{ id: 1, something: 'bla' }])
            }
          }
        }
        get do
          [{ id: 1, something: 'bla' }]
        end

        desc 'This gets a something.', {
          documentation: {
            example_request: {
              params: {
                id: 1
              }
            },
            example_response: {
              body: JSON.generate({ id: 1, something: 'bla' })
            }
          }
        }
        params do
          requires :id, type: Integer
        end
        get ':id' do
          { id: params[:id], something: 'bla' }
        end

        params do
          requires :id, type: Integer
        end
        put ':id' do
          { id: params[:id], something: 'bla updated' }
        end

        desc 'This creates a something.', {
          documentation: {
            example_request: {
              params: {
                id: 1,
                text: 'new bla'
              }
            },
            example_response: {
              code: 201,
              body: JSON.generate({ id: 1, something: 'new bla' })
            }
          }
        }
        params do
          requires :id, type: Integer
          requires :text, type: String
        end
        post ':id' do
          { id: params[:id], something: params[:text] }
        end
      end

      add_swagger_documentation
    end
  end

  def app; DocumentationExampleApi; end

  it "should include example request and response when specified" do
    get '/swagger_doc/somethings.json'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.1",
      "basePath" => "http://example.org",
      "resourcePath" => "",
      "apis" => [
        { "path" => "/somethings.{format}",
          "operations" => [
            { "notes" => nil,
              "summary" => "This gets all somethings.",
              "nickname" => "GET-somethings---format-",
              "httpMethod" => "GET",
              "parameters" => [],
              "exampleResponse" => {
                "code" => 200,
                "headers" => { "Content-Type" => "application/json" },
                "body" => JSON.generate([{ id: 1, something: 'bla' }])
              }
            }
          ]
        },
        { "path" => "/somethings/{id}.{format}",
          "operations" => [
             { "notes" => nil,
               "summary" => "This gets a something.",
               "nickname" => "GET-somethings--id---format-",
               "httpMethod" => "GET",
               "parameters" => [
                 { "paramType" => "path",
                   "name" => "id",
                   "description" => nil,
                   "dataType" => "Integer",
                   "required" => true
                 }
               ],
               "exampleRequest" => {
                 "params" => {
                   "id" => 1
                 }
               },
               "exampleResponse" => {
                 "code" => 200,
                 "headers" => { "Content-Type" => "application/json" },
                 "body" => JSON.generate({ id: 1, something: 'bla' })
               }
             }
           ]
         },
         { "path" => "/somethings/{id}.{format}",
           "operations" => [
             { "notes" => nil,
               "summary" => "",
               "nickname" => "PUT-somethings--id---format-",
               "httpMethod" => "PUT",
               "parameters" => [
                 { "paramType" => "path",
                   "name" => "id",
                   "description" => nil,
                   "dataType" => "Integer",
                   "required" => true
                 }
               ]
             }
           ]
         },
         { "path" => "/somethings/{id}.{format}",
           "operations" => [
             { "notes" => nil,
               "summary" => "This creates a something.",
               "nickname" => "POST-somethings--id---format-",
               "httpMethod" => "POST",
               "parameters" => [
                 { "paramType" => "path",
                   "name" => "id",
                   "description" => nil,
                   "dataType" => "Integer",
                   "required" => true
                 },
                 { "paramType" => "form",
                   "name" => "text",
                   "description" => nil,
                   "dataType" => "String",
                   "required" => true
                 }
               ],
               "exampleRequest" => {
                 "params" => {
                   "id" => 1,
                   "text" => "new bla"
                 }
               },
               "exampleResponse" => {
                 "code" => 201,
                 "headers" => { "Content-Type" => "application/json" },
                 "body" => JSON.generate({ id: 1, something: 'new bla' })
               }
             }
           ]
         }
       ]
    }
  end

end
