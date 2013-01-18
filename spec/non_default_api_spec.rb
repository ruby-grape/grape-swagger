require 'spec_helper'

describe "options: " do
  context "overruling the basepath" do
    before(:all) do
      class BasePathMountedApi < Grape::API
        desc 'this gets something'
        get '/something' do
          {:bla => 'something'}
        end
      end

      class SimpleApiWithBasePath < Grape::API
        NON_DEFAULT_BASE_PATH= "http://www.breakcoregivesmewood.com"

        mount BasePathMountedApi
        add_swagger_documentation :base_path => NON_DEFAULT_BASE_PATH
      end
    end

    def app; SimpleApiWithBasePath end

    it "retrieves the given base-path on /swagger_doc" do
      get '/swagger_doc'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"#{SimpleApiWithBasePath::NON_DEFAULT_BASE_PATH}\", :operations=>[], :apis=>[{:path=>\"/swagger_doc/something.{format}\"}, {:path=>\"/swagger_doc/swagger_doc.{format}\"}]}"
    end

    it "retrieves the same given base-path for mounted-api" do
      get '/swagger_doc/something'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"#{SimpleApiWithBasePath::NON_DEFAULT_BASE_PATH}\", :resourcePath=>\"\", :apis=>[{:path=>\"/something.{format}\", :operations=>[{:notes=>nil, :summary=>\"this gets something\", :nickname=>\"GET-something---format-\", :httpMethod=>\"GET\", :parameters=>[]}]}]}"
    end
  end

  context "overruling the version" do
    before(:all) do
      class ApiVersionMountedApi < Grape::API
        desc 'this gets something'
        get '/something' do
          {:bla => 'something'}
        end
      end

      class SimpleApiWithApiVersion < Grape::API
        API_VERSION = "101"

        mount ApiVersionMountedApi
        add_swagger_documentation :api_version => API_VERSION
      end
    end

    def app; SimpleApiWithApiVersion end

    it "retrieves the api version on /swagger_doc" do
      get '/swagger_doc'
      last_response.body.should == "{:apiVersion=>\"#{SimpleApiWithApiVersion::API_VERSION}\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :operations=>[], :apis=>[{:path=>\"/swagger_doc/something.{format}\"}, {:path=>\"/swagger_doc/swagger_doc.{format}\"}]}"
    end

    it "retrieves the same api version for mounted-api" do
      get '/swagger_doc/something'
      last_response.body.should == "{:apiVersion=>\"#{SimpleApiWithApiVersion::API_VERSION}\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :resourcePath=>\"\", :apis=>[{:path=>\"/something.{format}\", :operations=>[{:notes=>nil, :summary=>\"this gets something\", :nickname=>\"GET-something---format-\", :httpMethod=>\"GET\", :parameters=>[]}]}]}"
    end
  end

  context "mounting in a versioned api" do
    before(:all) do
      class SimpleApiToMountInVersionedApi < Grape::API
        desc 'this gets something'
        get '/something' do
          {:bla => 'something'}
        end
      end

      class SimpleApiWithVersionInPath < Grape::API
        version 'v1', :using => :path

        mount SimpleApiToMountInVersionedApi
        add_swagger_documentation
      end
    end

    def app; SimpleApiWithVersionInPath end

    it "should get the documentation on a versioned path /v1/swagger_doc" do
      get '/v1/swagger_doc'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :operations=>[], :apis=>[{:path=>\"/v1/swagger_doc/something.{format}\"}, {:path=>\"/v1/swagger_doc/swagger_doc.{format}\"}]}"
    end

    it "should get the resource specific documentation on a versioned path /v1/swagger_doc/something" do
      get '/v1/swagger_doc/something'
      last_response.status.should == 200
    end

  end


  context "overruling hiding the documentation paths" do
    before(:all) do
      class HideDocumentationPathMountedApi < Grape::API
        desc 'this gets something'
        get '/something' do
          {:bla => 'something'}
        end
      end

      class SimpleApiWithHiddenDocumentation < Grape::API
        mount HideDocumentationPathMountedApi
        add_swagger_documentation :hide_documentation_path => true
      end
    end

    def app; SimpleApiWithHiddenDocumentation end

    it "it doesn't show the documentation path on /swagger_doc" do
      get '/swagger_doc'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :operations=>[], :apis=>[{:path=>\"/swagger_doc/something.{format}\"}]}"
    end
  end

  context "overruling the mount-path" do
    before(:all) do
      class DifferentMountMountedApi < Grape::API
        desc 'this gets something'
        get '/something' do
          {:bla => 'something'}
        end
      end

      class SimpleApiWithDifferentMount < Grape::API
        MOUNT_PATH = "/api_doc"

        mount DifferentMountMountedApi
        add_swagger_documentation :mount_path => MOUNT_PATH
      end
    end

    def app; SimpleApiWithDifferentMount end

    it "retrieves the given base-path on /api_doc" do
      get '/api_doc'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :operations=>[], :apis=>[{:path=>\"/api_doc/something.{format}\"}, {:path=>\"/api_doc/api_doc.{format}\"}]}"
    end

    it "retrieves the same given base-path for mounted-api" do
      get '/api_doc/something'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :resourcePath=>\"\", :apis=>[{:path=>\"/something.{format}\", :operations=>[{:notes=>nil, :summary=>\"this gets something\", :nickname=>\"GET-something---format-\", :httpMethod=>\"GET\", :parameters=>[]}]}]}"
    end

    it "does not respond to swagger_doc" do
      get '/swagger_doc'
      last_response.status.should be == 404
    end
  end

  context "overruling the markdown" do
    before(:all) do
      class MarkDownMountedApi < Grape::API
        desc 'this gets something', {
          :notes => '_test_'
        }
        get '/something' do
          {:bla => 'something'}
        end
      end

      class SimpleApiWithMarkdown < Grape::API
        mount MarkDownMountedApi
        add_swagger_documentation :markdown => true
      end
    end

    def app; SimpleApiWithMarkdown end

    it "parses markdown for a mounted-api" do
      get '/swagger_doc/something'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :resourcePath=>\"\", :apis=>[{:path=>\"/something.{format}\", :operations=>[{:notes=>\"<p><em>test</em></p>\\n\", :summary=>\"this gets something\", :nickname=>\"GET-something---format-\", :httpMethod=>\"GET\", :parameters=>[]}]}]}"
    end
  end

  context "versioned API" do
    before(:all) do
      class VersionedMountedApi < Grape::API
        prefix 'api'
        version 'v1'

        desc 'this gets something'
        get '/something' do
          {:bla => 'something'}
        end
      end

      class SimpleApiWithVersion < Grape::API
        mount VersionedMountedApi
        add_swagger_documentation :api_version => "v1"
      end
    end

    def app; SimpleApiWithVersion end

    it "parses version and places it in the path" do
      get '/swagger_doc/api'
      last_response.body.should == "{:apiVersion=>\"v1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :resourcePath=>\"\", :apis=>[{:path=>\"/api/v1/something.{format}\", :operations=>[{:notes=>nil, :summary=>\"this gets something\", :nickname=>\"GET-api--version-something---format-\", :httpMethod=>\"GET\", :parameters=>[]}]}]}"
    end
  end

  context "protected API" do
    before(:all) do
      class ProtectedApi < Grape::API
        desc 'this gets something'
        get '/something' do
          {:bla => 'something'}
        end
      end
  
      class SimpleApiWithProtection < Grape::API
        mount ProtectedApi
        add_swagger_documentation
      end
    end
  
    def app; SimpleApiWithProtection; end

    it "should use https schema in mount point" do
      get '/swagger_doc', {}, 'rack.url_scheme' => 'https'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"https://example.org\", :operations=>[], :apis=>[{:path=>\"/swagger_doc/something.{format}\"}, {:path=>\"/swagger_doc/swagger_doc.{format}\"}]}" 
    end

    it "should use https schema in endpoint doc" do
      get '/swagger_doc/something', {}, 'rack.url_scheme' => 'https'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"https://example.org\", :resourcePath=>\"\", :apis=>[{:path=>\"/something.{format}\", :operations=>[{:notes=>nil, :summary=>\"this gets something\", :nickname=>\"GET-something---format-\", :httpMethod=>\"GET\", :parameters=>[]}]}]}"
    end
  end
end
