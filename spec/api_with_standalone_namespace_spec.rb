require 'spec_helper'

describe 'Standalone namespace API' do
  let(:json_body) { JSON.parse(last_response.body) }

  describe 'with "path" versioning' do
    before do
      class StandaloneApiWithPathVersioning < Grape::API
        format :json
        version 'v1', using: :path

        namespace :store do
          get
          # will be assigned to standalone the namespace below
          namespace :orders do
            get :order_id
          end
        end

        namespace 'store/orders', swagger: { nested: false } do
          post :order_idx
          namespace 'actions' do
            get 'dummy'
          end
          namespace 'actions2', swagger: { nested: false } do
            get 'dummy2'
            namespace 'actions22' do
              get 'dummy22'
            end
          end
        end

        namespace 'store/:store_id/orders', swagger: { nested: false, name: 'specific-store-orders' } do
          delete :order_id
        end

        add_swagger_documentation api_version: 'v1'
      end
    end

    def app
      StandaloneApiWithPathVersioning
    end

    describe 'retrieves swagger-documentation on /swagger_doc' do
      before { get '/v1/swagger_doc' }

      it 'that contains all api paths' do
        expect(json_body['apis']).to eq(
          [
            { 'path' => '/store.{format}', 'description' => 'Operations about stores' },
            { 'path' => '/store_orders.{format}', 'description' => 'Operations about store/orders' },
            { 'path' => '/store_orders_actions2.{format}', 'description' => 'Operations about store/orders/actions2s' },
            { 'path' => '/specific-store-orders.{format}', 'description' => 'Operations about store/:store_id/orders' },
            { 'path' => '/swagger_doc.{format}', 'description' => 'Operations about swagger_docs' }
          ]
        )
      end
    end

    describe 'retrieved namespace swagger-documentation on /swagger_doc/store' do
      before { get '/v1/swagger_doc/store' }
      it 'does not include standalone namespaces' do
        apis = json_body['apis']
        # shall include 1 route, GET on store
        expect(apis.length).to eql(1)
        expect(apis[0]['operations'][0]['method']).to eql('GET')
      end
    end

    describe 'retrieved namespace swagger-documentation on /swagger_doc/store_orders' do
      before { get '/v1/swagger_doc/store_orders' }
      it 'does not assign namespaces within standalone namespaces to the general resource' do
        apis = json_body['apis']
        # shall include 3 routes, get on store, get with order_id and get dummy on actions
        expect(apis.length).to eql(3)
      end
    end

    describe 'retrieved namespace swagger-documentation on /swagger_doc/store_orders_actions2' do
      before { get '/v1/swagger_doc/store_orders_actions2' }
      it 'does appear as standalone namespace within another standalone namespace' do
        apis = json_body['apis']
        # shall include 2 routes, get on dummy2 and get on dummy22
        expect(apis.length).to eql(2)
        expect(apis[0]['operations'][0]['method']).to eql('GET')
        expect(apis[1]['operations'][0]['method']).to eql('GET')
      end
    end

    describe 'retrieved namespace swagger-documentation on /swagger_doc/specific-store-orders' do
      before { get '/v1/swagger_doc/specific-store-orders' }
      it 'does show the one route' do
        apis = json_body['apis']
        # shall include 1 routes, delete action
        expect(apis.length).to eql(1)
        expect(apis[0]['operations'][0]['method']).to eql('DELETE')
      end
    end

    describe 'retrieved namespace swagger-documentation on /swagger_doc/store_orders' do
      before { get '/v1/swagger_doc/store_orders_actions2' }
      it 'does work with standalone in standalone namespaces' do
        apis = json_body['apis']
        # shall include 2 routes, dummy2 and dummy22
        expect(apis.length).to eql(2)
      end
    end
  end

  describe 'with header versioning' do
    before do
      class StandaloneApiWithHeaderVersioning < Grape::API
        format :json
        version 'v1', using: :header, vendor: 'grape-swagger'

        namespace :store do
          get
          # will be assigned to standalone the namespace below
          namespace :orders do
            get :order_id
          end
        end

        namespace 'store/orders', swagger: { nested: false } do
          post :order_idx
          namespace 'actions' do
            get 'dummy'
          end
          namespace 'actions2', swagger: { nested: false } do
            get 'dummy2'
            namespace 'actions22' do
              get 'dummy22'
            end
          end
        end

        namespace 'store/:store_id/orders', swagger: { nested: false, name: 'specific-store-orders' } do
          delete :order_id
        end

        add_swagger_documentation api_version: 'v1'
      end
    end

    def app
      StandaloneApiWithHeaderVersioning
    end

    describe 'retrieves swagger-documentation on /swagger_doc' do
      before { get 'swagger_doc' }

      it 'that contains all api paths' do
        expect(json_body['apis']).to eq(
          [
            { 'path' => '/store.{format}', 'description' => 'Operations about stores' },
            { 'path' => '/store_orders.{format}', 'description' => 'Operations about store/orders' },
            { 'path' => '/store_orders_actions2.{format}', 'description' => 'Operations about store/orders/actions2s' },
            { 'path' => '/specific-store-orders.{format}', 'description' => 'Operations about store/:store_id/orders' },
            { 'path' => '/swagger_doc.{format}', 'description' => 'Operations about swagger_docs' }
          ]
        )
      end
    end

    describe 'retrieved namespace swagger-documentation on /swagger_doc/store' do
      before { get '/swagger_doc/store' }
      it 'does not include standalone namespaces' do
        apis = json_body['apis']
        # shall include 1 route, GET on store
        expect(apis.length).to eql(1)
        expect(apis[0]['operations'][0]['method']).to eql('GET')
      end
    end

    describe 'retrieved namespace swagger-documentation on /swagger_doc/store_orders' do
      before { get '/swagger_doc/store_orders' }
      it 'does not assign namespaces within standalone namespaces to the general resource' do
        apis = json_body['apis']
        # shall include 3 routes, get on store, get with order_id and get dummy on actions
        expect(apis.length).to eql(3)
      end
    end

    describe 'retrieved namespace swagger-documentation on /swagger_doc/store_orders_actions2' do
      before { get '/swagger_doc/store_orders_actions2' }
      it 'does appear as standalone namespace within another standalone namespace' do
        apis = json_body['apis']
        # shall include 2 routes, get on dummy2 and get on dummy22
        expect(apis.length).to eql(2)
        expect(apis[0]['operations'][0]['method']).to eql('GET')
        expect(apis[1]['operations'][0]['method']).to eql('GET')
      end
    end

    describe 'retrieved namespace swagger-documentation on /swagger_doc/specific-store-orders' do
      before { get '/swagger_doc/specific-store-orders' }
      it 'does show the one route' do
        apis = json_body['apis']
        # shall include 1 routes, delete action
        expect(apis.length).to eql(1)
        expect(apis[0]['operations'][0]['method']).to eql('DELETE')
      end
    end

    describe 'retrieved namespace swagger-documentation on /swagger_doc/store_orders' do
      before { get '/swagger_doc/store_orders_actions2' }
      it 'does work with standalone in standalone namespaces' do
        apis = json_body['apis']
        # shall include 2 routes, dummy2 and dummy22
        expect(apis.length).to eql(2)
      end
    end
  end
end
