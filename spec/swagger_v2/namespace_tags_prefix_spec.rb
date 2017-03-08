# frozen_string_literal: true
require 'spec_helper'

describe 'namespace tags check while using prefix and version' do
  include_context 'namespace example'

  before :all do
    module TheApi
      class NamespaceApi < Grape::API
        version [:v1, :v2]
      end

      class CascadingVersionApi < Grape::API
        version :v2

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
      end
    end

    class TagApi < Grape::API
      prefix :api
      mount TheApi::CascadingVersionApi
      mount TheApi::NamespaceApi
      add_swagger_documentation
    end
  end

  def app
    TagApi
  end

  describe 'retrieves swagger-documentation on /swagger_doc' do
    subject do
      get '/api/swagger_doc.json'
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

      expect(subject['paths']['/api/v1/hudson']['get']['tags']).to eql(['hudson'])
      expect(subject['paths']['/api/v1/colorado/simple']['get']['tags']).to eql(['colorado'])
      expect(subject['paths']['/api/v1/colorado/simple-test']['get']['tags']).to eql(['colorado'])
      expect(subject['paths']['/api/v1/thames/simple_with_headers']['get']['tags']).to eql(['thames'])
      expect(subject['paths']['/api/v1/niles/items']['post']['tags']).to eql(['niles'])
      expect(subject['paths']['/api/v1/niles/custom']['get']['tags']).to eql(['niles'])
      expect(subject['paths']['/api/v2/hudson']['get']['tags']).to eql(['hudson'])
      expect(subject['paths']['/api/v2/colorado/simple']['get']['tags']).to eql(['colorado'])
    end
  end

  describe 'retrieves the documentation for mounted-api' do
    subject do
      get '/api/swagger_doc/colorado.json'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['tags']).to eql(
        [
          { 'name' => 'colorado', 'description' => 'Operations about colorados' }
        ]
      )

      expect(subject['paths']['/api/v1/colorado/simple']['get']['tags']).to eql(['colorado'])
      expect(subject['paths']['/api/v1/colorado/simple-test']['get']['tags']).to eql(['colorado'])
    end

    describe 'includes headers' do
      subject do
        get '/api/swagger_doc/thames.json'
        JSON.parse(last_response.body)
      end

      specify do
        expect(subject['tags']).to eql(
          [
            { 'name' => 'thames', 'description' => 'Operations about thames' }
          ]
        )

        expect(subject['paths']['/api/v1/thames/simple_with_headers']['get']['tags']).to eql(['thames'])
      end
    end
  end
end
