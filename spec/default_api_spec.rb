require 'spec_helper'

describe "Default API" do

  before :all do
    class NotAMountedApi < Grape::API
      format :json
      desc 'This gets something.'
      get '/something' do
        { bla: 'something' }
      end
      add_swagger_documentation
    end
  end

  def app; NotAMountedApi; end

  it "should document something" do
    get '/swagger_doc'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.1",
      "basePath" => "http://example.org",
      "operations" => [],
      "apis" => [
        { "path" => "/swagger_doc/something.{format}" },
        { "path" => "/swagger_doc/swagger_doc.{format}" }
      ]
    }
  end

end
