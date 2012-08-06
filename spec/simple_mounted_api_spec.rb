require 'spec_helper'

describe "a simple mounted api" do
  before(:all) do
    class SimpleMountedApi < Grape::API
      desc 'this gets something', {
        :notes => '_test_'
      }
      get '/simple' do
        {:bla => 'something'}
      end
    end

    class SimpleApi < Grape::API
      mount SimpleMountedApi
      add_swagger_documentation
    end
  end

  def app; SimpleApi end

  it "retrieves swagger-documentation on /swagger_doc" do
    get '/swagger_doc'
    last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :operations=>[], :apis=>[{:path=>\"/swagger_doc/simple.{format}\"}, {:path=>\"/swagger_doc/swagger_doc.{format}\"}]}"
  end

  it "retrieves the documentation for mounted-api" do
    get '/swagger_doc/simple'
    last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :resourcePath=>\"\", :apis=>[{:path=>\"/simple.{format}\", :operations=>[{:notes=>\"_test_\", :summary=>\"this gets something\", :nickname=>\"GET-simple---format-\", :httpMethod=>\"GET\", :parameters=>[]}]}]}"
  end
end
