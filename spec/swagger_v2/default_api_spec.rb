require 'spec_helper'
# require 'grape_version'

describe 'Default API' do
  context 'with no additional options' do
    def app
      Class.new(Grape::API) do
        format :json
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
        add_swagger_documentation
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'documents api' do
      expect(subject).to eq(
        {
          "info"=>{"title"=>"API title", "version"=>"v1"},
          "swagger"=>"2.0",
          "produces"=>["application/json"],
          "host"=>"example.org",
          "paths"=>{
            "/something"=>{
              "get"=>{
                "produces"=>["application/json"],
                "responses"=>{"200"=>{"description"=>"get Something(s)", "schema"=>{"$ref"=>"#/definitions/Something"}}}}}},
            "definitions"=>{}}
      )
    end

    context 'path inside the apis array' do
      it 'starts with a forward slash' do
        subject['paths'].each do |path|
          expect(path.first).to start_with '/'
        end
      end
    end
  end

  context 'with additional option block given to desc', if: GrapeVersion.satisfy?('>= 0.12.0') do
    def app
      Class.new(Grape::API) do
        format :json
        desc 'This gets something.' do
          detail 'more details about the endpoint'
        end
        get '/something' do
          { bla: 'something' }
        end
        add_swagger_documentation
      end
    end

    subject do
      get '/swagger_doc/something'
      JSON.parse(last_response.body)
    end

    it 'documents endpoint' do
      expect(subject).to eq({
        "info"=>{"title"=>"API title", "version"=>"v1"},
        "swagger"=>"2.0",
        "produces"=>["application/json"],
        "host"=>"example.org",
        "paths"=>{
          "/something"=>{
            "get"=>{
              "produces"=>["application/json"],
              "responses"=>{"200"=>{"description"=>"get Something(s)", "schema"=>{"$ref"=>"#/definitions/Something"}}}}}},
              "definitions"=>{}
      })
    end
  end

  context 'with additional info' do
    def app
      Class.new(Grape::API) do
        format :json
        add_swagger_documentation info: {
          title: 'My API Title',
          description: 'A description of my API',
          license: 'Apache 2',
          license_url: 'http://test.com',
          terms_of_service_url: 'http://terms.com',
          contact_email: 'support@test.com'
        }
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)['info']
    end

    it 'documents API title' do
      expect(subject['title']).to eql('My API Title')
    end

    it 'documents API description' do
      expect(subject['description']).to eql('A description of my API')
    end

    it 'should document the license' do
      expect(subject['license']['name']).to eql('Apache 2')
    end

    it 'documents the license url' do
      expect(subject['license']['url']).to eql('http://test.com')
    end

    it 'documents the terms of service url' do
      expect(subject['termsOfServiceUrl']).to eql('http://terms.com')
    end

    it 'documents the contact email' do
      expect(subject['contact']['contact_email']).to eql('support@test.com')
    end
  end
end
