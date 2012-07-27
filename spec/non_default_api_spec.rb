require 'spec_helper'

describe "overruling the defaults for the api documentation generation" do

  class MountedApi < Grape::API
    desc 'this gets something'
    get '/something' do
      {:bla => 'something'}
    end
  end


  context "overruling the basepath" do
    class SimpleApiWithBasePath < Grape::API
      NON_DEFAULT_BASE_PATH= "http://www.breakcoregivesmewood.com"

      mount MountedApi
      add_swagger_documentation :base_path => NON_DEFAULT_BASE_PATH
    end

    subject { SimpleApiWithBasePath.new }
    def app; subject end

    it "retrieves the given base-path on /swagger_doc" do
      get '/swagger_doc'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"#{SimpleApiWithBasePath::NON_DEFAULT_BASE_PATH}\", :operations=>[], :apis=>[{:path=>\"/swagger_doc/something.{format}\"}, {:path=>\"/swagger_doc/swagger_doc.{format}\"}]}"
    end

    it "retrieves the same given base-path for mounted-api" do
      Random.stub(:rand) { 0 }
      get '/swagger_doc/something'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"#{SimpleApiWithBasePath::NON_DEFAULT_BASE_PATH}\", :resourcePath=>\"\", :apis=>[{:path=>\"/something.{format}\", :operations=>[{:notes=>nil, :summary=>\"this gets something\", :nickname=>0, :httpMethod=>\"GET\", :parameters=>[]}]}]}"
    end
  end

  context "overruling the basepath" do
    class SimpleApiWithAPiVersion < Grape::API
      API_VERSION = "101"

      mount MountedApi
      add_swagger_documentation :api_version => API_VERSION
    end

    subject { SimpleApiWithAPiVersion.new }
    def app; subject end

    it "retrieves the given base-path on /swagger_doc" do
      get '/swagger_doc'
      last_response.body.should == "{:apiVersion=>\"#{SimpleApiWithAPiVersion::API_VERSION}\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :operations=>[], :apis=>[{:path=>\"/swagger_doc/something.{format}\"}, {:path=>\"/swagger_doc/swagger_doc.{format}\"}]}"
    end

    it "retrieves the same given base-path for mounted-api" do
      Random.stub(:rand) { 0 }
      get '/swagger_doc/something'
      last_response.body.should == "{:apiVersion=>\"#{SimpleApiWithAPiVersion::API_VERSION}\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :resourcePath=>\"\", :apis=>[{:path=>\"/something.{format}\", :operations=>[{:notes=>nil, :summary=>\"this gets something\", :nickname=>0, :httpMethod=>\"GET\", :parameters=>[]}]}]}"
    end
  end

  context "overruling the mount-path" do
    class SimpleApiWithDifferentMount < Grape::API
      MOUNT_PATH = "api_doc"

      mount MountedApi
      add_swagger_documentation :mount_path => MOUNT_PATH
    end

    subject { SimpleApiWithDifferentMount.new }
    def app; subject end

    it "retrieves the given base-path on /swagger_doc" do
      get '/api_doc'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :operations=>[], :apis=>[{:path=>\"/swagger_doc/something.{format}\"}, {:path=>\"/swagger_doc/swagger_doc.{format}\"}]}"
    end

    it "retrieves the same given base-path for mounted-api" do
      Random.stub(:rand) { 0 }
      get '/api_doc/something'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :resourcePath=>\"\", :apis=>[{:path=>\"/something.{format}\", :operations=>[{:notes=>nil, :summary=>\"this gets something\", :nickname=>0, :httpMethod=>\"GET\", :parameters=>[]}]}]}"
    end

    it "does not respond to swagger_doc" do
      get '/swagger_doc'
      last_response.status.should be == 404
    end
  end


end
