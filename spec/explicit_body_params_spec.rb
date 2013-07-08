require 'spec_helper'

describe "api with body_params option" do
  before :all do
    class BodyParamsApi < Grape::API
      desc 'This posts something.', :notes => "whatever"
      params do
        requires :foo
      end
      post '/something' do
        { bla: 'something' }
      end

      desc 'This posts something else.', {
        :notes => "whatever",
        :body_param => true
      }
      params do
        requires :foo
        requires :bar
      end
      post '/something_else' do
        { bla: 'something_else' }
      end

      add_swagger_documentation
    end
  end

  def app; BodyParamsApi end

  it "returns 'form' paramType without explicit option" do
    get '/swagger_doc/something.json'

    operation = JSON.parse(last_response.body)["apis"][0]["operations"][0]
    parameters = operation["parameters"]
    parameters.size.should == 1
    parameters[0]["paramType"].should == "form"
  end

  it "returns 'body' paramType with explicit option" do
    get '/swagger_doc/something_else.json'

    operation = JSON.parse(last_response.body)["apis"][0]["operations"][0]
    operation["parameters"].should == [{
      "name" => "body",
      "paramType" => "body",
      "required" => true,
      "description" => "",
      "dataType" => "String"
    }]
  end
end
