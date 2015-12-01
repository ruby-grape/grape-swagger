require 'spec_helper'

describe 'entities exposing an array' do
  before :all do
    module TheApi
      module Entities
        class ApiError < Grape::Entity
          expose :code, documentation: { type: Integer }
          expose :message, documentation: { type: String }
        end

        class UseHeader < Grape::Entity
          present_collection true
          expose :items, as: 'diagnoses', using: Entities::ApiError, documentation: { is_array: true }
          expose :others, documentation: { type: String }
        end
      end

      class HeadersApi < Grape::API
        format :json

        desc 'This returns something',
          headers:  {
            "X-Rate-Limit-Limit": {
              "description": "The number of allowed requests in the current period",
              "type": "integer"
          }},

          entity: Entities::UseHeader
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
        "info"=>{
          "title"=>"API title",
          "version"=>"v1"
        },
        "swagger"=>"2.0",
        "produces"=>["application/json"],
        "host"=>"example.org",
        "paths"=>{
          "/use_headers"=>{
            "get"=>{
              "produces"=>["application/json"],
              "responses"=>{
                "200"=>{
                  "description"=>"This returns something",
                  "schema"=>{
                    "$ref"=>"#/definitions/UseHeader"}}},
              "headers"=>{
                "X-Rate-Limit-Limit"=>{
                  "description"=>"The number of allowed requests in the current period",
                  "type"=>"integer"
              }}}}},
        "definitions"=>{
          "UseHeader"=>{
            "type"=>"object",
            "properties"=>{
              "diagnoses"=>{"$ref"=>"#/definitions/ApiError"},
              "others"=>{"type"=>"string"}
          }},
          "ApiError"=>{
            "type"=>"object",
            "properties"=>{
              "code"=>{"type"=>"integer"},
              "message"=>{"type"=>"string"}
      }}}})
    end
  end
end
