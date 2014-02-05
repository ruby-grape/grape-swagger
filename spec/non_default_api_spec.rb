require 'spec_helper'

describe "options: " do
  context "overriding the basepath" do
    before :all do

      class BasePathMountedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithBasePath < Grape::API
        NON_DEFAULT_BASE_PATH = "http://www.breakcoregivesmewood.com"

        mount BasePathMountedApi
        add_swagger_documentation :base_path => NON_DEFAULT_BASE_PATH
      end

    end

    def app; SimpleApiWithBasePath end

    it "retrieves the given base-path on /swagger_doc" do
      get '/swagger_doc.json'
      JSON.parse(last_response.body)["basePath"].should == SimpleApiWithBasePath::NON_DEFAULT_BASE_PATH
    end

    it "retrieves the same given base-path for mounted-api" do
      get '/swagger_doc/something.json'
      JSON.parse(last_response.body)["basePath"].should == SimpleApiWithBasePath::NON_DEFAULT_BASE_PATH
    end
  end

  context "overriding the basepath with a proc" do
    before :all do

      class ProcBasePathMountedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithProcBasePath < Grape::API
        mount ProcBasePathMountedApi
        add_swagger_documentation base_path: lambda { |request| "#{request.base_url}/some_value" }
      end
    end

    def app; SimpleApiWithProcBasePath end

    it "retrieves the given base-path on /swagger_doc" do
      get '/swagger_doc.json'
      JSON.parse(last_response.body)["basePath"].should == "http://example.org/some_value"
    end

    it "retrieves the same given base-path for mounted-api" do
      get '/swagger_doc/something.json'
      JSON.parse(last_response.body)["basePath"].should == "http://example.org/some_value"
    end
  end

  context "relative base_path" do
    before :all do

      class RelativeBasePathMountedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithRelativeBasePath < Grape::API
        mount RelativeBasePathMountedApi
        add_swagger_documentation base_path: "/some_value"
      end
    end

    def app; SimpleApiWithRelativeBasePath end

    it "retrieves the given base-path on /swagger_doc" do
      get '/swagger_doc.json'
      JSON.parse(last_response.body)["basePath"].should == "http://example.org/some_value"
    end

    it "retrieves the same given base-path for mounted-api" do
      get '/swagger_doc/something.json'
      JSON.parse(last_response.body)["basePath"].should == "http://example.org/some_value"
    end
  end

  context "overriding the version" do
    before :all do

      class ApiVersionMountedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
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
      get '/swagger_doc.json'
      JSON.parse(last_response.body)["apiVersion"].should == SimpleApiWithApiVersion::API_VERSION
    end

    it "retrieves the same api version for mounted-api" do
      get '/swagger_doc/something.json'
      JSON.parse(last_response.body)["apiVersion"].should == SimpleApiWithApiVersion::API_VERSION
    end
  end

  context "mounting in a versioned api" do
    before :all do

      class SimpleApiToMountInVersionedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithVersionInPath < Grape::API
        version 'v1', :using => :path

        mount SimpleApiToMountInVersionedApi
        add_swagger_documentation
      end
    end

    def app; SimpleApiWithVersionInPath end

    it "gets the documentation on a versioned path /v1/swagger_doc" do
      get '/v1/swagger_doc.json'

      JSON.parse(last_response.body).should == {
        "apiVersion" => "0.1",
        "swaggerVersion" => "1.2",
        "basePath" => "http://example.org",
        "info" => {},
        "produces" => ["application/xml", "application/json", "text/plain"],
        "operations" => [],
        "apis" => [
          { "path" => "/v1/swagger_doc/something.{format}" },
          { "path" => "/v1/swagger_doc/swagger_doc.{format}" }
        ]
      }
    end

    it "gets the resource specific documentation on a versioned path /v1/swagger_doc/something" do
      get '/v1/swagger_doc/something.json'
      last_response.status.should == 200
      JSON.parse(last_response.body).should == {
        "apiVersion" => "0.1",
        "swaggerVersion" => "1.2",
        "basePath" => "http://example.org",
        "resourcePath" => "",
        "apis" => [{
          "path" => "/0.1/something.{format}",
          "operations" => [{
            "produces" => ["application/xml", "application/json", "text/plain"],
            "notes" => nil,
            "notes" => "",
            "summary" => "This gets something.",
            "nickname" => "GET--version-something---format-",
            "httpMethod" => "GET",
            "parameters" => []
          }]
        }]
      }
    end

  end

  context "overriding hiding the documentation paths" do
    before :all do
      class HideDocumentationPathMountedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithHiddenDocumentation < Grape::API
        mount HideDocumentationPathMountedApi
        add_swagger_documentation :hide_documentation_path => true
      end
    end

    def app; SimpleApiWithHiddenDocumentation end

    it "it doesn't show the documentation path on /swagger_doc" do
      get '/swagger_doc.json'
      JSON.parse(last_response.body).should == {
        "apiVersion" => "0.1",
        "swaggerVersion" => "1.2",
        "basePath" => "http://example.org",
        "info" => {},
        "produces" => ["application/xml", "application/json", "text/plain"],
        "operations" => [],
        "apis" => [
          { "path" => "/swagger_doc/something.{format}" }
        ]
      }
    end
  end

  context "overriding hiding the documentation paths in prefixed API" do
    before :all do
      class HideDocumentationPathPrefixedMountedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class PrefixedApiWithHiddenDocumentation < Grape::API
        prefix "abc"
        mount HideDocumentationPathPrefixedMountedApi
        add_swagger_documentation :hide_documentation_path => true
      end

    end

    def app; PrefixedApiWithHiddenDocumentation end

    it "it doesn't show the documentation path on /abc/swagger_doc/something.json" do
      get '/abc/swagger_doc/something.json'
      JSON.parse(last_response.body).should == {
        "apiVersion"=>"0.1",
        "swaggerVersion"=>"1.2",
        "basePath"=>"http://example.org",
        "resourcePath"=>"",
        "apis"=> [{
          "path"=>"/abc/something.{format}",
          "operations"=> [{
            "produces" => ["application/xml", "application/json", "text/plain"],
            "notes"=>nil,
            "notes"=>"",
            "summary"=>"This gets something.",
            "nickname"=>"GET-abc-something---format-",
            "httpMethod"=>"GET",
            "parameters"=>[]
          }]
        }]
      }
    end

  end

  context "overriding hiding the documentation paths in prefixed and versioned API" do
    before :all do
      class HideDocumentationPathMountedApi2 < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class PrefixedAndVersionedApiWithHiddenDocumentation < Grape::API
        prefix "abc"
        version 'v20', :using => :path

        mount HideDocumentationPathMountedApi2

        add_swagger_documentation :hide_documentation_path => true, :api_version => self.version
      end
    end

    def app; PrefixedAndVersionedApiWithHiddenDocumentation end

    it "it doesn't show the documentation path on /abc/v1/swagger_doc/something.json" do
      get '/abc/v20/swagger_doc/something.json'

      JSON.parse(last_response.body).should == {
        "apiVersion"=>"v20",
        "swaggerVersion"=>"1.2",
        "basePath"=>"http://example.org",
        "resourcePath"=>"",
        "apis"=>[{
          "path"=>"/abc/v20/something.{format}",
          "operations"=>[{
            "produces" => ["application/xml", "application/json", "text/plain"],
            "notes"=>nil,
            "notes"=>"",
            "summary"=>"This gets something.",
            "nickname"=>"GET-abc--version-something---format-",
            "httpMethod"=>"GET",
            "parameters"=>[]
          }]
        }]
      }
    end

  end

  context "overriding the mount-path" do
    before :all do
      class DifferentMountMountedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
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
      get '/api_doc.json'
        JSON.parse(last_response.body)["apis"].each do |api|
        api["path"].should start_with SimpleApiWithDifferentMount::MOUNT_PATH
      end
    end

    it "retrieves the same given base-path for mounted-api" do
      get '/api_doc/something.json'
      JSON.parse(last_response.body)["apis"].each do |api|
        api["path"].should_not start_with SimpleApiWithDifferentMount::MOUNT_PATH
      end
    end

    it "does not respond to swagger_doc" do
      get '/swagger_doc.json'
      last_response.status.should be == 404
    end
  end

  context "overriding the markdown" do
    before :all do
      class MarkDownMountedApi < Grape::API
        desc 'This gets something.', {
          :notes => '_test_'
        }
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithMarkdown < Grape::API
        mount MarkDownMountedApi
        add_swagger_documentation :markdown => true
      end
    end

    def app; SimpleApiWithMarkdown end

    it "parses markdown for a mounted-api" do
      get '/swagger_doc/something.json'
      JSON.parse(last_response.body).should ==  {
        "apiVersion" => "0.1",
        "swaggerVersion" => "1.2",
        "basePath" => "http://example.org",
        "resourcePath" => "",
        "apis" => [{
          "path" => "/something.{format}",
          "operations" => [{
            "produces" => ["application/xml", "application/json", "text/plain"],
            "notes" => "<p><em>test</em></p>\n",
            "summary" => "This gets something.",
            "nickname" => "GET-something---format-",
            "httpMethod" => "GET",
            "parameters" => []
          }]
        }]
      }
    end
  end

  context "prefixed and versioned API" do
    before :all do
      class VersionedMountedApi < Grape::API
        prefix 'api'
        version 'v1'

        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithVersion < Grape::API
        mount VersionedMountedApi
        add_swagger_documentation :api_version => "v1"
      end
    end

    def app; SimpleApiWithVersion end

    it "parses version and places it in the path" do
      get '/swagger_doc/something.json'

      JSON.parse(last_response.body)["apis"].each do |api|
        api["path"].should start_with "/api/v1/"
      end
    end
  end

  context "protected API" do
    before :all do
      class ProtectedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithProtection < Grape::API
        mount ProtectedApi
        add_swagger_documentation
      end
    end

    def app; SimpleApiWithProtection; end

    it "uses https schema in mount point" do
      get '/swagger_doc.json', {}, 'rack.url_scheme' => 'https'
      JSON.parse(last_response.body)["basePath"].should == "https://example.org:80"
    end

    it "uses https schema in endpoint doc" do
      get '/swagger_doc/something.json', {}, 'rack.url_scheme' => 'https'
      JSON.parse(last_response.body)["basePath"].should == "https://example.org:80"
    end
  end

  context ":hide_format" do
    before :all do
      class HidePathsApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithHiddenPaths < Grape::API
        mount ProtectedApi
        add_swagger_documentation :hide_format => true
      end
    end

    def app; SimpleApiWithHiddenPaths; end

    it "has no formats" do
      get '/swagger_doc/something.json'
      JSON.parse(last_response.body)["apis"].each do |api|
        api["path"].should_not end_with ".{format}"
      end
    end
  end

  context "multiple documentations" do
    before :all do
      class FirstApi < Grape::API
        desc 'This is the first API'
        get '/first' do
          { first: 'hip' }
        end

        add_swagger_documentation mount_path: '/first/swagger_doc'
      end

      class SecondApi < Grape::API
        desc 'This is the second API'
        get '/second' do
          { second: 'hop' }
        end

        add_swagger_documentation mount_path: '/second/swagger_doc'
      end

      class SimpleApiWithMultipleMountedDocumentations < Grape::API
        mount FirstApi
        mount SecondApi
      end
    end

    def app; SimpleApiWithMultipleMountedDocumentations; end

    it "retrieves the first swagger-documentation on /first/swagger_doc" do
      get '/first/swagger_doc.json'
      JSON.parse(last_response.body).should == {
        "apiVersion" => "0.1",
        "swaggerVersion" => "1.2",
        "basePath" => "http://example.org",
        "info" => {},
        "produces" => ["application/xml", "application/json", "text/plain"],
        "operations" => [],
        "apis" => [
          { "path" => "/first/swagger_doc/first.{format}" }
        ]
      }
    end

    it "retrieves the second swagger-documentation on /second/swagger_doc" do
      get '/second/swagger_doc.json'
      JSON.parse(last_response.body).should == {
        "apiVersion" => "0.1",
        "swaggerVersion" => "1.2",
        "basePath" => "http://example.org",
        "info" => {},
        "produces" => ["application/xml", "application/json", "text/plain"],
        "operations" => [],
        "apis" => [
          { "path" => "/second/swagger_doc/second.{format}" }
        ]
      }
    end
  end

  context ":formatting" do
    before :all do
      class JSONDefaultFormatAPI < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleJSONFormattedAPI < Grape::API
        mount JSONDefaultFormatAPI
        add_swagger_documentation format: :json
      end
    end

    def app; SimpleJSONFormattedAPI; end

    it "defaults to JSON format when none is specified" do
      get '/swagger_doc/something'

      lambda{ JSON.parse(last_response.body) }.should_not raise_error
    end

  end
end
