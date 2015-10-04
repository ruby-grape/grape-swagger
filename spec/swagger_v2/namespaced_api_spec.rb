require 'spec_helper'

describe 'namespace' do
  context 'at root level' do
    def app
      Class.new(Grape::API) do
        namespace :aspace do
          get '/', desc: 'Description for aspace'
        end
        add_swagger_documentation format: :json
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)['paths']['/aspace']['get']
    end

    it 'shows the namespace description in the json spec' do
      expect(subject['description']).to eql('Description for aspace')
    end
  end

  context 'mounted' do
    def app
      namespaced_api = Class.new(Grape::API) do
        namespace :bspace do
          get '/', desc: 'Description for aspace'
        end
      end

      Class.new(Grape::API) do
        mount namespaced_api
        add_swagger_documentation format: :json
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)['paths']['/bspace']['get']
    end

    it 'shows the namespace description in the json spec' do
      expect(subject['description']).to eql('Description for aspace')
    end
  end
end
