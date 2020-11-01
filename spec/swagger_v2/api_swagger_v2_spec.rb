# frozen_string_literal: true

require 'spec_helper'

describe 'swagger spec v2.0' do
  include_context "#{MODEL_PARSER} swagger example"

  def app
    Class.new(Grape::API) do
      format :json

      #  Thing stuff
      desc 'This gets Things.' do
        params Entities::Something.documentation
        http_codes [{ code: 401, message: 'Unauthorized', model: Entities::ApiError }]
      end
      get '/thing' do
        something = OpenStruct.new text: 'something'
        present something, with: Entities::Something
      end

      desc 'This gets Things.' do
        http_codes [
          { code: 200, message: 'get Horses', model: Entities::Something },
          { code: 401, message: 'HorsesOutError', model: Entities::ApiError }
        ]
      end
      get '/thing2' do
        something = OpenStruct.new text: 'something'
        present something, with: Entities::Something
      end

      desc 'This gets Thing.' do
        http_codes [{ code: 200, message: 'getting a single thing' }, { code: 401, message: 'Unauthorized' }]
      end
      params do
        requires :id, type: Integer
      end
      get '/thing/:id' do
        something = OpenStruct.new text: 'something'
        present something, with: Entities::Something
      end

      desc 'This creates Thing.',
           success: Entities::Something
      params do
        requires :text, type: String, documentation: { type: 'string', desc: 'Content of something.' }
        requires :links, type: Array, documentation: { type: 'link', is_array: true }
      end
      post '/thing', http_codes: [{ code: 422, message: 'Unprocessible Entity' }] do
        something = OpenStruct.new text: 'something'
        present something, with: Entities::Something
      end

      desc 'This updates Thing.',
           success: Entities::Something
      params do
        requires :id, type: Integer
        optional :text, type: String, desc: 'Content of something.'
        optional :links, type: Array, documentation: { type: 'link', is_array: true }
      end
      put '/thing/:id' do
        something = OpenStruct.new text: 'something'
        present something, with: Entities::Something
      end

      desc 'This deletes Thing.',
           entity: Entities::Something
      params do
        requires :id, type: Integer
      end
      delete '/thing/:id' do
        something = OpenStruct.new text: 'something'
        present something, with: Entities::Something
      end

      desc 'dummy route.',
           failure: [{ code: 401, message: 'Unauthorized' }]
      params do
        requires :id, type: Integer
      end
      delete '/dummy/:id' do
        {}
      end

      namespace :other_thing do
        desc 'nested route inside namespace',
             entity: Entities::QueryInput,
             x: {
               'amazon-apigateway-auth' => { type: 'none' },
               'amazon-apigateway-integration' => { type: 'aws', uri: 'foo_bar_uri', httpMethod: 'get' }
             }

        params do
          requires :elements, documentation: {
            type: 'QueryInputElement',
            desc: 'Set of configuration',
            param_type: 'body',
            is_array: true,
            required: true
          }
        end
        get '/:elements' do
          present something, with: Entities::QueryInput
        end
      end

      version 'v3', using: :path
      add_swagger_documentation api_version: 'v1',
                                base_path: '/api',
                                info: {
                                  title: 'The API title to be displayed on the API homepage.',
                                  description: 'A description of the API.',
                                  contact_name: 'Contact name',
                                  contact_email: 'Contact@email.com',
                                  contact_url: 'Contact URL',
                                  license: 'The name of the license.',
                                  license_url: 'www.The-URL-of-the-license.org',
                                  terms_of_service_url: 'www.The-URL-of-the-terms-and-service.com'
                                }
    end
  end

  describe 'whole documentation' do
    subject do
      get '/v3/swagger_doc'
      JSON.parse(last_response.body)
    end

    describe 'swagger object' do
      describe 'required keys' do
        it { expect(subject.keys).to include 'swagger' }
        it { expect(subject['swagger']).to eql '2.0' }
        it { expect(subject.keys).to include 'info' }
        it { expect(subject['info']).to be_a Hash }
        it { expect(subject.keys).to include 'paths' }
        it { expect(subject['paths']).to be_a Hash }
      end

      describe 'info object required keys' do
        let(:info) { subject['info'] }

        it { expect(info.keys).to include 'title' }
        it { expect(info['title']).to be_a String }
        it { expect(info.keys).to include 'version' }
        it { expect(info['version']).to be_a String }

        describe 'license object' do
          let(:license) { subject['info']['license'] }

          it { expect(license.keys).to include 'name' }
          it { expect(license['name']).to be_a String }
          it { expect(license.keys).to include 'url' }
          it { expect(license['url']).to be_a String }
        end

        describe 'contact object' do
          let(:contact) { subject['info']['contact'] }

          it { expect(contact.keys).to include 'name' }
          it { expect(contact['name']).to be_a String  }
          it { expect(contact.keys).to include 'email' }
          it { expect(contact['email']).to be_a String }
          it { expect(contact.keys).to include 'url' }
          it { expect(contact['url']).to be_a String }
        end

        describe 'global tags' do
          let(:tags) { subject['tags'] }

          it { expect(tags).to be_a Array }
          it { expect(tags).not_to be_empty }
        end
      end

      describe 'path object' do
        let(:paths) { subject['paths'] }

        it 'hides documentation paths per default' do
          expect(paths.keys).not_to include '/swagger_doc', '/swagger_doc/{name}'
        end

        specify do
          paths.each_pair do |path, value|
            expect(path).to start_with('/')
            expect(value).to be_a Hash
            expect(value).not_to be_empty

            value.each do |method, declaration|
              expect(http_verbs).to include method
              expect(declaration).to have_key('responses')

              declaration['responses'].each do |status_code, response|
                expect(status_code).to match(/\d{3}/)
                expect(response).to have_key('description')
              end
            end
          end
        end
      end

      describe 'definitions object' do
        let(:definitions) { subject['definitions'] }

        specify do
          definitions.each do |model, properties|
            expect(model).to match(/\w+/)
            expect(properties).to have_key('properties')
          end
        end
      end
    end

    describe 'swagger file' do
      it do
        expect(subject).to eql swagger_json
      end
    end
  end

  describe 'specific resource documentation' do
    subject do
      get '/v3/swagger_doc/other_thing'
      JSON.parse(last_response.body)
    end

    let(:tags) { subject['tags'] }
    specify do
      expect(tags).to eql [
        {
          'name' => 'other_thing',
          'description' => 'Operations about other_things'
        }
      ]
    end
  end
end
