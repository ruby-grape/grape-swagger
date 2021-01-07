# frozen_string_literal: true

RSpec.shared_context 'namespace example' do
  before :all do
    module TheApi
      # rubocop:disable Lint/EmptyClass
      class CustomType; end
      # rubocop:enable Lint/EmptyClass

      class NamespaceApi < Grape::API
        namespace :hudson do
          desc 'Document root'
          get '/' do
            { message: 'hi' }
          end
        end

        namespace :colorado do
          desc 'This gets something.',
               notes: '_test_'

          get '/simple' do
            { bla: 'something' }
          end
        end

        namespace :colorado do
          desc 'This gets something for URL using - separator.',
               notes: '_test_'

          get '/simple-test' do
            { bla: 'something' }
          end
        end

        namespace :thames do
          desc 'this gets something else',
               headers: {
                 'XAuthToken' => { description: 'A required header.', required: true },
                 'XOtherHeader' => { description: 'An optional header.', required: false }
               },
               http_codes: [
                 { code: 403, message: 'invalid pony' },
                 { code: 405, message: 'no ponies left!' }
               ]

          get '/simple_with_headers' do
            { bla: 'something_else' }
          end
        end

        namespace :niles do
          desc 'this takes an array of parameters',
               params: {
                 'items[]' => { description: 'array of items', is_array: true }
               }

          post '/items' do
            {}
          end
        end

        namespace :niles do
          desc 'this uses a custom parameter',
               params: {
                 'custom' => { type: CustomType, description: 'array of items', is_array: true }
               }

          get '/custom' do
            {}
          end
        end
      end

      class ParentLessNamespaceApi < Grape::API
        route_param :animal do
          route_param :breed do
            resource :queues do
              route_param :queue_id do
                resource :reservations do
                  desc 'Lists all reservations specific type of animal of specific breed in specific queue'
                  get do
                    { bla: 'Bla Black' }
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
