# frozen_string_literal: true

require 'spec_helper'

describe 'swagger spec v2.0' do
  describe 'mounted APIs' do
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
        add_swagger_documentation base_path: '/api',
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

    mounted_paths.each do |expected_path|
      describe "documents only #{expected_path} paths" do
        let(:mount_path) { "/v3/swagger_doc#{expected_path}" }
        subject do
          get mount_path
          JSON.parse(last_response.body)['paths']
        end

        specify do
          unexpected_paths = mounted_paths - [expected_path]
          subject.each_key do |path|
            unexpected_paths.each do |unexpected_path|
              expect(path).not_to start_with unexpected_path
            end
            expect(path).to start_with(expected_path).or include(expected_path)
            expect(subject[path]).to eql swagger_json['paths'][path]
          end
        end
      end
    end
  end
end
