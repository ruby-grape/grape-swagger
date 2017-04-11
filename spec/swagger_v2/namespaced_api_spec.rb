# frozen_string_literal: true

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

    it 'shows the namespace summary in the json spec' do
      expect(subject['summary']).to eql('Description for aspace')
    end
  end

  context 'with camel case namespace' do
    def app
      Class.new(Grape::API) do
        namespace :camelCases do
          get '/', desc: 'Look! An endpoint.'
        end
        add_swagger_documentation format: :json
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)['paths']['/camelCases']['get']
    end

    it 'shows the namespace summary in the json spec' do
      expect(subject['summary']).to eql('Look! An endpoint.')
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

    it 'shows the namespace summary in the json spec' do
      expect(subject['summary']).to eql('Description for aspace')
    end
  end

  context 'mounted under a route' do
    def app
      namespaced_api = Class.new(Grape::API) do
        namespace :bspace do
          get '/', desc: 'Description for aspace'
        end
      end

      Class.new(Grape::API) do
        mount namespaced_api => '/mounted'
        add_swagger_documentation format: :json
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)['paths']['/mounted/bspace']['get']
    end

    it 'shows the namespace summary in the json spec' do
      expect(subject['summary']).to eql('Description for aspace')
    end
  end

  context 'arbitrary mounting' do
    def app
      inner_namespaced_api = Class.new(Grape::API) do
        namespace :bspace do
          get '/', desc: 'Description for aspace'
        end
      end

      outer_namespaced_api = Class.new(Grape::API) do
        mount inner_namespaced_api => '/mounted'
      end

      Class.new(Grape::API) do
        mount outer_namespaced_api => '/'
        add_swagger_documentation format: :json
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)['paths']['/mounted/bspace']['get']
    end

    it 'shows the namespace summary in the json spec' do
      expect(subject['summary']).to eql('Description for aspace')
    end
  end
end
