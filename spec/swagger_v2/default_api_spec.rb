# frozen_string_literal: true

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
        'info' => { 'title' => 'API title', 'version' => '0.0.1' },
        'swagger' => '2.0',
        'produces' => ['application/json'],
        'host' => 'example.org',
        'tags' => [{ 'name' => 'something', 'description' => 'Operations about somethings' }],
        'paths' => {
          '/something' => {
            'get' => {
              'description' => 'This gets something.',
              'produces' => ['application/json'],
              'parameters' => [],
              'tags' => ['something'],
              'operationId' => 'getSomething',
              'responses' => { '200' => { 'description' => 'This gets something.' } }
            }
          }
        }
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
        desc 'This gets something.'
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
      expect(subject).to eq('info' => { 'title' => 'API title', 'version' => '0.0.1' },
                            'swagger' => '2.0',
                            'produces' => ['application/json'],
                            'host' => 'example.org',
                            'tags' => [{ 'name' => 'something', 'description' => 'Operations about somethings' }],
                            'paths' => {
                              '/something' => {
                                'get' => {
                                  'description' => 'This gets something.',
                                  'produces' => ['application/json'],
                                  'parameters' => [],
                                  'tags' => ['something'],
                                  'operationId' => 'getSomething',
                                  'responses' => { '200' => { 'description' => 'This gets something.' } }
                                }
                              }
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
          contact_email: 'support@test.com',
          x: {
            logo: 'http://logo.com/img.png'
          }
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
      expect(subject['termsOfService']).to eql('http://terms.com')
    end

    it 'documents the contact email' do
      expect(subject['contact']['email']).to eql('support@test.com')
    end

    it 'documents the extension field' do
      expect(subject['x-logo']).to eql('http://logo.com/img.png')
    end
  end

  context 'with tags' do
    def app
      Class.new(Grape::API) do
        format :json
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
        get '/somethingelse' do
          { bla: 'somethingelse' }
        end

        add_swagger_documentation tags: [
          { name: 'something', description: 'customized description' }
        ]
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'documents the customized tag' do
      expect(subject['tags']).to eql(
        [
          { 'name' => 'somethingelse', 'description' => 'Operations about somethingelses' },
          { 'name' => 'something', 'description' => 'customized description' }
        ]
      )
    end
  end
end
