require 'spec_helper'

describe "a simple mounted api" do

  class MountedApi < Grape::API
    desc 'this gets something'
    get '/something' do
      {:bla => 'something'}
    end
  end

  class SimpleApi < Grape::API
    mount MountedApi
    add_swagger_documentation
  end

  subject { SimpleApi.new }
  def app; subject end

  it "retrieves swagger-documentation on /swagger_doc" do
    get '/swagger_doc'
    last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :operations=>[], :apis=>[{:path=>\"/swagger_doc/mountedapi.{format}\"}, {:path=>\"/swagger_doc/swagger_doc.{format}\"}]}"
  end

  it "retrieves the documentation for mounted-api" do
    Random.stub(:rand) { 0 }
    get '/swagger_doc/mountedapi'
    last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :resourcePath=>\"\", :apis=>[{:path=>\"/something.{format}\", :operations=>[{:notes=>nil, :summary=>\"this gets something\", :nickname=>0, :httpMethod=>\"GET\", :parameters=>[]}]}]}"
  end
end