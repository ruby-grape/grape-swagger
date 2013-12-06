require 'spec_helper'

describe "Default API" do

  context 'with no additional options' do
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
        "swaggerVersion" => "1.2",
        "basePath" => "http://example.org",
        "info" => {},
        "produces" => ["application/json"],
        "operations" => [],
        "apis" => [
          { "path" => "/swagger_doc/something.{format}" },
          { "path" => "/swagger_doc/swagger_doc.{format}" }
        ]
      }
    end
    
    context "path inside the apis array" do
      it "should start with a forward slash" do
        get '/swagger_doc'
        JSON.parse(last_response.body)['apis'].each do |api|
          api['path'].should start_with "/"
        end
      end
    end
  end

  context 'with API info' do
    before :all do
      class ApiInfoTest < Grape::API
        format :json
        add_swagger_documentation info: {
          title: 'My API Title',
          description: 'A description of my API',
          license: 'Apache 2',
          license_url: 'http://test.com',
          terms_of_service_url: 'http://terms.com',
          contact: 'support@test.com'
        }
      end
      get '/swagger_doc'
    end

    def app; ApiInfoTest; end

    subject do
      JSON.parse(last_response.body)['info']
    end

    it 'should document API title' do
      expect(subject['title']).to eql('My API Title')
    end

    it 'should document API description' do
      expect(subject['description']).to eql('A description of my API')
    end

    it 'should document the license' do
      expect(subject['license']).to eql('Apache 2')
    end

    it 'should document the license url' do
      expect(subject['licenseUrl']).to eql('http://test.com')
    end

    it 'should document the terms of service url' do
      expect(subject['termsOfServiceUrl']).to eql('http://terms.com')
    end

    it 'should document the contact email' do
      expect(subject['contact']).to eql('support@test.com')
    end
  end

end
