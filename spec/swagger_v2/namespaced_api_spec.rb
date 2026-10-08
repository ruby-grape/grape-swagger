# frozen_string_literal: true

require 'spec_helper'

describe 'namespace' do
  context 'at root level' do
    def app
      Class.new(Grape::API) do
        namespace :aspace do
          desc 'Description for aspace'
          get '/'
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

  context 'with camel case namespace' do
    def app
      Class.new(Grape::API) do
        namespace :camelCases do
          desc 'Look! An endpoint.'
          get '/'
        end
        add_swagger_documentation format: :json
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)['paths']['/camelCases']['get']
    end

    it 'shows the namespace description in the json spec' do
      expect(subject['description']).to eql('Look! An endpoint.')
    end
  end

  context 'mounted' do
    def app
      namespaced_api = Class.new(Grape::API) do
        namespace :bspace do
          desc 'Description for aspace'
          get '/'
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

  context 'mounted under a route' do
    def app
      namespaced_api = Class.new(Grape::API) do
        namespace :bspace do
          desc 'Description for aspace'
          get '/'
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

    it 'shows the namespace description in the json spec' do
      expect(subject['description']).to eql('Description for aspace')
    end
  end

  context 'arbitrary mounting' do
    def app
      inner_namespaced_api = Class.new(Grape::API) do
        namespace :bspace do
          desc 'Description for aspace'
          get '/'
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

    it 'shows the namespace description in the json spec' do
      expect(subject['description']).to eql('Description for aspace')
    end
  end

  context 'get with desc: option' do
    def app
      Class.new(Grape::API) do
        namespace :aspace do
          get '/', desc: 'passthrough, not the desc DSL'
        end
        add_swagger_documentation format: :json
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)['paths']['/aspace']['get']
    end

    it 'does not treat get desc: as a swagger summary or description' do
      expect(subject).not_to include('summary')
      expect(subject).not_to include('description')
    end
  end
end
