require 'spec_helper'

describe "a simple mounted api" do
  before(:all) do
    class SimpleMountedApi < Grape::API
      desc "Document root"
      get do
      end

      desc 'this gets something', {
        :notes => '_test_'
      }

      get '/simple' do
        {:bla => 'something'}
      end

      desc 'this gets something else', {
        :headers => {
          "XAuthToken" => {description: "A required header.", required: true},
          "XOtherHeader" => {description: "An optional header.", required: false}
        },
        :http_codes => {
          403 => "invalid pony",
          405 => "no ponies left!"
        }
      }
      get '/simple_with_headers' do
        {:bla => 'something_else'}
      end
    end
  end

  context "without base path" do
    before(:all) do
      class SimpleApi < Grape::API
        mount SimpleMountedApi
        add_swagger_documentation
      end
    end

    def app; SimpleApi end

    it "retrieves swagger-documentation on /swagger_doc" do
      get '/swagger_doc'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :operations=>[], :apis=>[{:path=>\"/swagger_doc/simple.{format}\"}, {:path=>\"/swagger_doc/simple_with_headers.{format}\"}, {:path=>\"/swagger_doc/swagger_doc.{format}\"}]}"
    end

    it "retrieves the documentation for mounted-api" do
      get '/swagger_doc/simple'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :resourcePath=>\"\", :apis=>[{:path=>\"/simple.{format}\", :operations=>[{:notes=>\"_test_\", :summary=>\"this gets something\", :nickname=>\"GET-simple---format-\", :httpMethod=>\"GET\", :parameters=>[]}]}]}"
    end

    it "retrieves the documentation for mounted-api that includes headers" do
      get '/swagger_doc/simple_with_headers'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org\", :resourcePath=>\"\", :apis=>[{:path=>\"/simple_with_headers.{format}\", :operations=>[{:notes=>nil, :summary=>\"this gets something else\", :nickname=>\"GET-simple_with_headers---format-\", :httpMethod=>\"GET\", :parameters=>[{:paramType=>\"header\", :name=>\"XAuthToken\", :description=>\"A required header.\", :dataType=>\"String\", :required=>true}, {:paramType=>\"header\", :name=>\"XOtherHeader\", :description=>\"An optional header.\", :dataType=>\"String\", :required=>false}], :errorResponses=>[{:code=>403, :reason=>\"invalid pony\"}, {:code=>405, :reason=>\"no ponies left!\"}]}]}]}"
    end
  end

  context "with absolute base path", focus: true do
    before(:all) do
      class SimpleApiWithAbsBase < Grape::API
        mount SimpleMountedApi
        add_swagger_documentation({base_path: 'http://api.example.org/grape-api'})
      end
    end

    def app; SimpleApiWithAbsBase end

    it "should return the absolute base path" do
      get '/swagger_doc'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://api.example.org/grape-api\", :operations=>[], :apis=>[{:path=>\"/swagger_doc/simple.{format}\"}, {:path=>\"/swagger_doc/simple_with_headers.{format}\"}, {:path=>\"/swagger_doc/swagger_doc.{format}\"}]}"
    end
  end

  context "with relative base path", focus: true do
    before(:all) do
      class SimpleApiWithRelBase < Grape::API
        mount SimpleMountedApi
        add_swagger_documentation({base_path: '/grape-api'})
      end
    end

    def app; SimpleApiWithRelBase end

    it "should return the relative base path" do
      get '/swagger_doc'
      last_response.body.should == "{:apiVersion=>\"0.1\", :swaggerVersion=>\"1.1\", :basePath=>\"http://example.org/grape-api\", :operations=>[], :apis=>[{:path=>\"/swagger_doc/simple.{format}\"}, {:path=>\"/swagger_doc/simple_with_headers.{format}\"}, {:path=>\"/swagger_doc/swagger_doc.{format}\"}]}"
    end
  end
end
