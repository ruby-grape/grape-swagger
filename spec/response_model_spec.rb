require 'spec_helper'

describe "responseModel" do
  before :all do
    module Entities
      class Something < Grape::Entity
        expose :text, :documentation => { :type => "string", :desc => "Content of something." }
      end

      class Error < Grape::Entity
        expose :code, :documentation => { :type => "string", :desc => "Error code" }
        expose :message, :documentation => { :type => "string", :desc => "Error message" }
      end
    end

    class ResponseModelApi < Grape::API
      format :json
      desc 'This returns something or an error', {
        entity: Entities::Something,
        http_codes: [
          [200, "OK", Entities::Something],
          [403, "Refused to return something", Entities::Error]
        ]
      }
      get '/something/:id' do
        if params[:id] == 1
          something = OpenStruct.new text: 'something'
          present something, with: Entities::Something
        else
          error = OpenStruct.new code: 'some_error', message: "Some error"
          present error, with: Entities::Error
        end
      end

      add_swagger_documentation
    end
  end

  def app; ResponseModelApi; end

  it "should document specified models" do
    get '/swagger_doc/something'
    parsed_response = JSON.parse(last_response.body)
    parsed_response["apis"][0]["operations"][0]["responseMessages"].should == 
      [
        {
          "code"=>200,
          "message"=>"OK",
          "responseModel"=>"Something"
        },
        {
          "code"=>403,
          "message"=>"Refused to return something",
          "responseModel"=>"Error"
        }
      ]
    parsed_response["models"].keys.should include "Error"
    parsed_response["models"]["Error"].should == {
      "id" => "Error",
      "name" => "Error",
      "properties" => {
        "code" => { "type" => "string", "description" => "Error code" },
        "message" => { "type" => "string", "description" => "Error message" }
      }
    }
  end
end
