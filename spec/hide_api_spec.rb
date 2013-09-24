require 'spec_helper'

describe "a hide mounted api" do
  before :all do
    class HideMountedApi < Grape::API
      desc 'Show this endpoint'
      get '/simple' do
        { :bla => 'something' }
      end

      desc 'Hide this endpoint', {
        :hidden => true
      }
      get '/hide' do
        { :bla => 'something_else' }
      end
    end

    class HideApi < Grape::API
      mount HideMountedApi
      add_swagger_documentation
    end
  end

  def app; HideApi end

  it "retrieves swagger-documentation that doesn't include hidden endpoint" do
    get '/swagger_doc.json'
    JSON.parse(last_response.body).should == {
      "apiVersion" => "0.1",
      "swaggerVersion" => "1.1",
      "basePath" => "http://example.org",
      "operations" => [],
      "apis" => [
        { "path" => "/swagger_doc/simple.{format}" },
        { "path" => "/swagger_doc/swagger_doc.{format}" }
      ]
    }
  end
end
