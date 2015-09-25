require 'spec_helper'

describe 'swagger spec v2.0' do
  describe 'API Models' do
    before :all do
      module Entities
        class Something < Grape::Entity
          expose :id, documentation: { type: Integer, desc: 'Identity of Something' }
          expose :text, documentation: { type: String, desc: 'Content of something.' }
          expose :links, documentation: { type: 'link', is_array: true }
          expose :others, documentation: { type: 'text', is_array: false }
        end

        class EnumValues < Grape::Entity
          expose :gender, documentation: { type: 'string', desc: 'Content of something.', values: %w(Male Female) }
          expose :number, documentation: { type: 'integer', desc: 'Content of something.', values: [1, 2]  }
        end

        class ComposedOf < Grape::Entity
          expose :part_text, documentation: { type: 'string', desc: 'Content of composedof.' }
        end

        class ComposedOfElse < Grape::Entity
          def self.entity_name
            'composed'
          end
          expose :part_text, documentation: { type: 'string', desc: 'Content of composedof else.' }
        end

        class SomeThingElse < Grape::Entity
          expose :else_text, documentation: { type: 'string', desc: 'Content of something else.' }
          expose :parts, using: Entities::ComposedOf, documentation: { type: 'ComposedOf',
                                                                       is_array: true,
                                                                       required: true }

          expose :part, using: Entities::ComposedOfElse, documentation: { type: 'composes' }
        end

        class AliasedThing < Grape::Entity
          expose :something, as: :post, using: Entities::Something, documentation: { type: 'Something', desc: 'Reference to something.' }
        end

        class FourthLevel < Grape::Entity
          expose :text, documentation: { type: 'string' }
        end

        class ThirdLevel < Grape::Entity
          expose :parts, using: Entities::FourthLevel, documentation: { type: 'FourthLevel' }
        end

        class SecondLevel < Grape::Entity
          expose :parts, using: Entities::ThirdLevel, documentation: { type: 'ThirdLevel' }
        end

        class FirstLevel < Grape::Entity
          expose :parts, using: Entities::SecondLevel, documentation: { type: 'SecondLevel' }
        end
        class QueryInputElement < Grape::Entity
          expose :key, documentation: {
            type: String, desc: 'Name of parameter', required: true }
          expose :value, documentation: {
            type: String, desc: 'Value of parameter', required: true }
        end

        class QueryInput < Grape::Entity
          expose :elements, using: Entities::QueryInputElement, documentation: {
            type: 'QueryInputElement',
            desc: 'Set of configuration',
            param_type: 'body',
            is_array: true,
            required: true
          }
        end

        class ThingWithRoot < Grape::Entity
          root 'things', 'thing'
          expose :text, documentation: { type: 'string', desc: 'Content of something.' }
        end

        class ApiError < Grape::Entity
          expose :code, documentation: { type: Integer, desc: 'status code' }
          expose :message, documentation: { type: String, desc: 'error message' }
        end

      end

    end

    def app
      Class.new(Grape::API) do
        format :json

        # Something stuff
        desc 'This gets Somethings.', entity: Entities::Something, params: Entities::Something.documentation
        get '/something' do
          something = OpenStruct.new text: 'something'
          present something, with: Entities::Something
        end

        desc 'This gets Something.', entity: Entities::Something, params: Entities::Something.documentation
        params do
          requires :id, type: Integer, desc: 'Identity'
        end
        get '/something/:id' do
          something = OpenStruct.new text: 'something'
          present something, with: Entities::Something
        end

        desc 'This creates Something.', entity: Entities::Something, params: Entities::Something.documentation
        params do
          requires :text, type: String, documentation: { type: 'string', desc: 'Content of something.' }
          requires :links, type: Array, documentation: { type: 'link', is_array: true }
        end
        post '/something' do
          something = OpenStruct.new text: 'something'
          present something, with: Entities::Something
        end

        desc 'This updates Something.', entity: Entities::Something, params: Entities::Something.documentation
        params do
          requires :id, type: Integer
          optional :text, type: String, documentation: { type: 'string', desc: 'Content of something.' }
          optional :links, type: Array, documentation: { type: 'link', is_array: true }
        end
        put '/something/:id' do
          something = OpenStruct.new text: 'something'
          present something, with: Entities::Something
        end

        desc 'This deletes something.', entity: Entities::Something, params: Entities::Something.documentation
        params do
          requires :id, type: Integer
        end
        delete '/something/:id' do
          something = OpenStruct.new text: 'something'
          present something, with: Entities::Something
        end

        #  Thing stuff
        desc 'This gets Things.' do
          params Entities::Something.documentation
          http_codes [ { code: 401, message: 'Unauthorized', model: Entities::ApiError } ]
        end
        get '/thing' do
          something = OpenStruct.new text: 'something'
          present something, with: Entities::Something
        end

        desc 'This gets Things.' do
          params Entities::Something.documentation
          http_codes [
            { code: 200, message: 'get Horses', model: Entities::EnumValues },
            { code: 401, message: 'HorsesOutError', model: Entities::ApiError }
          ]
        end
        get '/thing2' do
          something = OpenStruct.new text: 'something'
          present something, with: Entities::Something
        end

        desc 'This gets Thing.' do
          params Entities::Something.documentation
          http_codes [ { code: 200, message: 'getting a single thing' }, { code: 401, message: 'Unauthorized' } ]
        end
        params do
          requires :id, type: Integer
        end
        get '/thing/:id' do
          something = OpenStruct.new text: 'something'
          present something, with: Entities::Something
        end

        desc 'This creates Thing.'
        params do
          requires :text, type: String, documentation: { type: 'string', desc: 'Content of something.' }
          requires :links, type: Array, documentation: { type: 'link', is_array: true }
        end
        post '/thing', http_codes: [ { code: 422, message: 'Unprocessible Entity' } ] do
          something = OpenStruct.new text: 'something'
          present something, with: Entities::Something
        end

        desc 'This updates Thing.'
        params do
          requires :id, type: Integer
          optional :text, type: String, desc: 'Content of something.'
          optional :links, type: Array, documentation: { type: 'link', is_array: true }
        end
        put '/thing/:id' do
          something = OpenStruct.new text: 'something'
          present something, with: Entities::Something
        end

        desc 'This deletes Thing.'
        params do
          requires :id, type: Integer
        end
        delete '/thing/:id' do
          something = OpenStruct.new text: 'something'
          present something, with: Entities::Something
        end

        namespace :otherthing do
          desc 'nested route inside namespace', params: Entities::QueryInput.documentation

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

        add_swagger_documentation api_version: 'v1',
                                  hide_format: true,
                                  base_path: '/api',
                                  info: {
                                    title: "The API title to be displayed on the API homepage.",
                                    description: "A description of the API.",
                                    contact_name: "Contact name",
                                    contact_email: "Contact@email.com",
                                    contact_url: "Contact URL",
                                    license: "The name of the license.",
                                    license_url: "www.The-URL-of-the-license.org",
                                    terms_of_service_url: "www.The-URL-of-the-terms-and-service.com",
                                  }
      end
    end


    before do
      get '/swagger_doc'
    end

    let(:json) { JSON.parse(last_response.body) }

    describe 'swagger object' do
      it 'does something' do
        ap json
      end

      describe 'required keys' do
        it { expect(json.keys).to include 'swagger' }
        it { expect(json['swagger']).to eql '2.0'  }
        it { expect(json.keys).to include 'info' }
        it { expect(json['info']).to be_a Hash  }
        it { expect(json.keys).to include 'paths' }
        it { expect(json['paths']).to be_a Hash  }
      end

      describe 'info object required keys' do
        let(:info) { json['info'] }

        it { expect(info.keys).to include 'title' }
        it { expect(info['title']).to be_a String  }
        it { expect(info.keys).to include 'version' }
        it { expect(info['version']).to be_a String  }

        describe 'license object' do
          let(:license) { json['info']['license'] }

          it { expect(license.keys).to include 'name' }
          it { expect(license['name']).to be_a String  }
          it { expect(license.keys).to include 'url' }
          it { expect(license['url']).to be_a String  }
        end

        describe 'contact object' do
          let(:contact) { json['info']['contact'] }

          it { expect(contact.keys).to include 'contact_name' }
          it { expect(contact['contact_name']).to be_a String  }
          it { expect(contact.keys).to include 'contact_email' }
          it { expect(contact['contact_email']).to be_a String  }
          it { expect(contact.keys).to include 'contact_url' }
          it { expect(contact['contact_url']).to be_a String  }
        end
      end

      describe 'path object' do
        let(:paths) { json['paths'] }
        it 'begins with slash' do
          paths.each_pair do |path, value|
            expect(path.start_with?('/')).to be true
            expect(value).to be_a Hash
          end
        end
      end

    end
  end
end
