# frozen_string_literal: true

require 'spec_helper'

describe 'nested body parameters for OAS 3.0' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApiOAS3
      class NestedBodyParamTypeApi < Grape::API
        namespace :simple_nested_params do
          desc 'post in body with nested parameters',
               detail: 'more details description',
               success: Entities::UseNestedWithAddress
          params do
            optional :contact, type: Hash, documentation: { additional_properties: true } do
              requires :name, type: String, documentation: { desc: 'name', in: 'body' }
              optional :addresses, type: Array do
                requires :street, type: String, documentation: { desc: 'street', in: 'body' }
                requires :postcode, type: String, documentation: { desc: 'postcode', in: 'body' }
                requires :city, type: String, documentation: { desc: 'city', in: 'body' }
                optional :country, type: String, documentation: { desc: 'country', in: 'body' }
              end
            end
          end

          post '/in_body' do
            { 'declared_params' => declared(params) }
          end

          desc 'put in body with nested parameters',
               detail: 'more details description',
               success: Entities::UseNestedWithAddress
          params do
            requires :id, type: Integer
            optional :name, type: String, documentation: { desc: 'name', in: 'body' }
            optional :address, type: Hash do
              optional :street, type: String, documentation: { desc: 'street', in: 'body' }
              optional :postcode, type: String, documentation: { desc: 'postcode', in: 'formData' }
              optional :city, type: String, documentation: { desc: 'city', in: 'body' }
              optional :country, type: String, documentation: { desc: 'country', in: 'body' }
            end
          end

          put '/in_body/:id' do
            { 'declared_params' => declared(params) }
          end
        end

        namespace :multiple_nested_params do
          desc 'put in body with multiple nested parameters',
               success: Entities::UseNestedWithAddress
          params do
            optional :contact, type: Hash do
              requires :name, type: String, documentation: { desc: 'name', in: 'body' }
              optional :addresses, type: Array do
                optional :street, type: String, documentation: { desc: 'street', in: 'body' }
                requires :postcode, type: Integer, documentation: { desc: 'postcode', in: 'formData' }
                optional :city, type: String, documentation: { desc: 'city', in: 'body' }
                optional :country, type: String, documentation: { desc: 'country', in: 'body' }
              end
              optional :delivery_address, type: Hash do
                optional :street, type: String, documentation: { desc: 'street', in: 'body' }
                optional :postcode, type: String, documentation: { desc: 'postcode', in: 'formData' }
                optional :city, type: String, documentation: { desc: 'city', in: 'body' }
                optional :country, type: String, documentation: { desc: 'country', in: 'body' }
              end
            end
          end

          post '/in_body' do
            { 'declared_params' => declared(params) }
          end

          desc 'put in body with multiple nested parameters',
               success: Entities::UseNestedWithAddress
          params do
            requires :id, type: Integer
            optional :name, type: String, documentation: { desc: 'name', in: 'body' }
            optional :address, type: Hash do
              optional :street, type: String, documentation: { desc: 'street', in: 'body' }
              requires :postcode, type: String, documentation: { desc: 'postcode', in: 'formData' }
              optional :city, type: String, documentation: { desc: 'city', in: 'body' }
              optional :country, type: String, documentation: { desc: 'country', in: 'body' }
            end
            optional :delivery_address, type: Hash do
              optional :street, type: String, documentation: { desc: 'street', in: 'body' }
              optional :postcode, type: String, documentation: { desc: 'postcode', in: 'formData' }
              optional :city, type: String, documentation: { desc: 'city', in: 'body' }
              optional :country, type: String, documentation: { desc: 'country', in: 'body' }
            end
          end

          put '/in_body/:id' do
            { 'declared_params' => declared(params) }
          end
        end

        namespace :nested_params_array do
          desc 'post in body with array of nested parameters',
               detail: 'more details description',
               success: Entities::UseNestedWithAddress
          params do
            optional :contacts, type: Array, documentation: { additional_properties: false } do
              requires :name, type: String, documentation: { desc: 'name', in: 'body' }
              optional :addresses, type: Array do
                requires :street, type: String, documentation: { desc: 'street', in: 'body' }
                requires :postcode, type: String, documentation: { desc: 'postcode', in: 'body' }
                requires :city, type: String, documentation: { desc: 'city', in: 'body' }
                optional :country, type: String, documentation: { desc: 'country', in: 'body' }
              end
            end
          end

          post '/in_body' do
            { 'declared_params' => declared(params) }
          end
        end

        add_swagger_documentation openapi_version: '3.0'
      end
    end
  end

  def app
    TheApiOAS3::NestedBodyParamTypeApi
  end

  describe 'nested body parameters given' do
    subject do
      get '/swagger_doc/simple_nested_params'
      JSON.parse(last_response.body)
    end

    describe 'POST' do
      let(:operation) { subject['paths']['/simple_nested_params/in_body']['post'] }

      it 'has requestBody with schema reference' do
        expect(operation['requestBody']).to include(
          'content' => {
            'application/json' => {
              'schema' => { '$ref' => '#/components/schemas/postSimpleNestedParamsInBody' }
            }
          }
        )
      end

      it 'has no body parameters' do
        params = operation['parameters'] || []
        body_params = params.select { |p| p['in'] == 'body' }
        expect(body_params).to be_empty
      end

      it 'defines nested schema in components' do
        schema = subject['components']['schemas']['postSimpleNestedParamsInBody']
        expect(schema['type']).to eq('object')
        expect(schema['description']).to eq('post in body with nested parameters')

        contact = schema['properties']['contact']
        expect(contact['type']).to eq('object')
        expect(contact['additionalProperties']).to eq(true)
        expect(contact['required']).to eq(%w[name])

        expect(contact['properties']['name']).to eq({
          'type' => 'string',
          'description' => 'name'
        })

        addresses = contact['properties']['addresses']
        expect(addresses['type']).to eq('array')
        expect(addresses['items']['type']).to eq('object')
        expect(addresses['items']['required']).to eq(%w[street postcode city])
        expect(addresses['items']['properties']['street']).to eq({
          'type' => 'string',
          'description' => 'street'
        })
      end
    end

    describe 'PUT' do
      let(:operation) { subject['paths']['/simple_nested_params/in_body/{id}']['put'] }

      it 'has path parameter with schema wrapper' do
        path_param = operation['parameters'].find { |p| p['in'] == 'path' }
        expect(path_param['name']).to eq('id')
        expect(path_param['required']).to eq(true)
        expect(path_param['schema']).to eq({ 'type' => 'integer', 'format' => 'int32' })
      end

      it 'has requestBody with schema reference' do
        expect(operation['requestBody']['content']['application/json']['schema']).to eq({
          '$ref' => '#/components/schemas/putSimpleNestedParamsInBodyId'
        })
      end

      it 'defines nested schema with address object' do
        schema = subject['components']['schemas']['putSimpleNestedParamsInBodyId']
        expect(schema['type']).to eq('object')

        expect(schema['properties']['name']).to eq({
          'type' => 'string',
          'description' => 'name'
        })

        address = schema['properties']['address']
        expect(address['type']).to eq('object')
        expect(address['properties']['street']).to eq({
          'type' => 'string',
          'description' => 'street'
        })
        expect(address['properties']['postcode']).to eq({
          'type' => 'string',
          'description' => 'postcode'
        })
      end
    end
  end

  describe 'multiple nested body parameters given' do
    subject do
      get '/swagger_doc/multiple_nested_params'
      JSON.parse(last_response.body)
    end

    describe 'POST' do
      let(:operation) { subject['paths']['/multiple_nested_params/in_body']['post'] }

      it 'has requestBody reference' do
        expect(operation['requestBody']['content']['application/json']['schema']).to eq({
          '$ref' => '#/components/schemas/postMultipleNestedParamsInBody'
        })
      end

      it 'defines schema with contact containing addresses and delivery_address' do
        schema = subject['components']['schemas']['postMultipleNestedParamsInBody']
        contact = schema['properties']['contact']

        expect(contact['type']).to eq('object')
        expect(contact['required']).to eq(%w[name])

        # addresses array
        addresses = contact['properties']['addresses']
        expect(addresses['type']).to eq('array')
        expect(addresses['items']['properties']['postcode']).to include(
          'type' => 'integer',
          'format' => 'int32'
        )
        expect(addresses['items']['required']).to eq(['postcode'])

        # delivery_address object
        delivery = contact['properties']['delivery_address']
        expect(delivery['type']).to eq('object')
        expect(delivery['properties']['street']).to eq({
          'type' => 'string',
          'description' => 'street'
        })
      end
    end

    describe 'PUT' do
      let(:operation) { subject['paths']['/multiple_nested_params/in_body/{id}']['put'] }

      it 'has path parameter and requestBody' do
        path_param = operation['parameters'].find { |p| p['in'] == 'path' }
        expect(path_param['name']).to eq('id')
        expect(path_param['schema']['type']).to eq('integer')

        expect(operation['requestBody']).to be_present
      end

      it 'defines schema with address and delivery_address' do
        schema = subject['components']['schemas']['putMultipleNestedParamsInBodyId']

        address = schema['properties']['address']
        expect(address['type']).to eq('object')
        expect(address['required']).to eq(['postcode'])

        delivery = schema['properties']['delivery_address']
        expect(delivery['type']).to eq('object')
        expect(delivery['properties']['city']).to eq({
          'type' => 'string',
          'description' => 'city'
        })
      end
    end
  end

  describe 'array of nested body parameters given' do
    subject do
      get '/swagger_doc/nested_params_array'
      JSON.parse(last_response.body)
    end

    describe 'POST' do
      let(:operation) { subject['paths']['/nested_params_array/in_body']['post'] }

      it 'has requestBody reference' do
        expect(operation['requestBody']['content']['application/json']['schema']).to eq({
          '$ref' => '#/components/schemas/postNestedParamsArrayInBody'
        })
      end

      it 'defines schema with contacts array containing nested addresses' do
        schema = subject['components']['schemas']['postNestedParamsArrayInBody']
        expect(schema['type']).to eq('object')
        expect(schema['description']).to eq('post in body with array of nested parameters')

        contacts = schema['properties']['contacts']
        expect(contacts['type']).to eq('array')

        contact_item = contacts['items']
        expect(contact_item['type']).to eq('object')
        expect(contact_item['additionalProperties']).to eq(false)
        expect(contact_item['required']).to eq(%w[name])

        addresses = contact_item['properties']['addresses']
        expect(addresses['type']).to eq('array')
        expect(addresses['items']['type']).to eq('object')
        expect(addresses['items']['required']).to eq(%w[street postcode city])
      end
    end
  end
end
