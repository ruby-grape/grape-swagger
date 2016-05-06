RSpec.shared_context 'namespace example' do
  before :all do
    module TheApi
      class CustomType; end

      class NamespaceApi < Grape::API
        namespace :hudson do
          desc 'Document root'
          get '/' do
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
    end
  end
end
