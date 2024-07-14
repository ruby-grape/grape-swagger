# frozen_string_literal: true

require 'spec_helper'

describe 'namespace tags check' do
  include_context 'namespace example'

  before :all do
    module TheApi
      class NamespaceApi2 < Grape::API
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

    class TestApi < Grape::API
      mount TheApi::NamespaceApi2
      add_swagger_documentation openapi_version: '3.0'
    end
  end

  def app
    TestApi
  end

  describe 'retrieves swagger-documentation on /swagger_doc' do
    subject do
      get '/swagger_doc.json'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['tags']).to eql(
        [
          { 'name' => 'hudson', 'description' => 'Operations about hudsons' },
          { 'name' => 'colorado', 'description' => 'Operations about colorados' },
          { 'name' => 'thames', 'description' => 'Operations about thames' },
          { 'name' => 'niles', 'description' => 'Operations about niles' }
        ]
      )

      expect(subject['paths']['/hudson']['get']['tags']).to eql(['hudson'])
      expect(subject['paths']['/colorado/simple']['get']['tags']).to eql(['colorado'])
      expect(subject['paths']['/colorado/simple-test']['get']['tags']).to eql(['colorado'])
      expect(subject['paths']['/thames/simple_with_headers']['get']['tags']).to eql(['thames'])
      expect(subject['paths']['/niles/items']['post']['tags']).to eql(['niles'])
      expect(subject['paths']['/niles/custom']['get']['tags']).to eql(['niles'])
    end
  end

  describe 'retrieves the documentation for mounted-api' do
    subject do
      get '/swagger_doc/colorado.json'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['tags']).to eql(
        [
          { 'name' => 'colorado', 'description' => 'Operations about colorados' }
        ]
      )

      expect(subject['paths']['/colorado/simple']['get']['tags']).to eql(['colorado'])
      expect(subject['paths']['/colorado/simple-test']['get']['tags']).to eql(['colorado'])
    end

    describe 'includes headers' do
      subject do
        get '/swagger_doc/thames.json'
        JSON.parse(last_response.body)
      end

      specify do
        expect(subject['tags']).to eql(
          [
            { 'name' => 'thames', 'description' => 'Operations about thames' }
          ]
        )

        expect(subject['paths']['/thames/simple_with_headers']['get']['tags']).to eql(['thames'])
      end
    end
  end
end
