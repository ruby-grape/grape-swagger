require 'spec_helper'

describe 'entities exposing an array' do
  include_context "the api entities"

  before :all do
    module TheApi
      class HeadersApi < Grape::API
        format :json

        desc 'This returns something',
          failure: [{code: 400, model: Entities::ApiError}],
          headers:  {
            "X-Rate-Limit-Limit" => {
              "description" => "The number of allowed requests in the current period",
              "type" => "integer"
          }},

          entity: Entities::UseResponse
        get '/use_headers' do
          { "declared_params" => declared(params) }
        end

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::HeadersApi
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe "it exposes a nested entity as array" do
    specify do
      expect(subject).to eql({
        "info"=>{"title"=>"API title", "version"=>"v1"},
        "swagger"=>"2.0",
        "produces"=>["application/json"],
        "host"=>"example.org",
        "schemes"=>["https", "http"],
        "paths"=>{
          "/use_headers"=>{
            "get"=>{
              "headers"=>{"X-Rate-Limit-Limit"=>{"description"=>"The number of allowed requests in the current period", "type"=>"integer"}},
              "produces"=>["application/json"],
              "responses"=>{
                "200"=>{"description"=>"This returns something", "schema"=>{"$ref"=>"#/definitions/UseResponse"}},
                "400"=>{"description"=>nil, "schema"=>{"$ref"=>"#/definitions/ApiError"}}
        }}}},
        "definitions"=>{
          "ResponseItem"=>{
            "type"=>"object",
            "properties"=>{"id"=>{"type"=>"integer"}, "name"=>{"type"=>"string"}}
          },
          "UseResponse"=>{
            "type"=>"object",
            "properties"=>{"description"=>{"type"=>"string"}, "$responses"=>{"$ref"=>"#/definitions/ResponseItem"}}
          },
          "ApiError"=>{
            "type"=>"object",
            "properties"=>{"code"=>{"type"=>"integer"}, "message"=>{"type"=>"string"}}}
      }})
    end
  end
end
