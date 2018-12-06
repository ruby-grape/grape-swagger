# frozen_string_literal: true

require 'spec_helper'

describe 'moving body/formData Params to definitions' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class NestedBodyParamTypeApi < Grape::API
        namespace :simple_nested_params do
          desc 'post in body with nested parameters',
               detail: 'more details description',
               success: Entities::UseNestedWithAddress
          params do
            optional :contact, type: Hash do
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

        add_swagger_documentation openapi_version: '3.0'
      end
    end
  end

  def app
    TheApi::NestedBodyParamTypeApi
  end

  describe 'nested body parameters given' do
    subject do
      get '/swagger_doc/simple_nested_params'
      JSON.parse(last_response.body)
    end

    describe 'POST' do
      let(:endpoint) { subject['paths']['/simple_nested_params/in_body']['post'] }

      specify do
        expect(endpoint['requestBody']['content']['application/json']).to eql(
          'schema' => {
            'properties' => {
              'SimpleNestedParamsInBody' => {
                '$ref' => '#/components/schemas/postSimpleNestedParamsInBody'
              }
            },
            'required' => ['SimpleNestedParamsInBody'], 'type' => 'object'
          }
        )
      end

      specify do
        expect(subject['components']['schemas']['postSimpleNestedParamsInBody']).to eql(
          'type' => 'object',
          'properties' => {
            'contact' => {
              'type' => 'object',
              'properties' => {
                'name' => { 'type' => 'string', 'description' => 'name' },
                'addresses' => {
                  'type' => 'array',
                  'items' => {
                    'type' => 'object',
                    'properties' => {
                      'street' => { 'type' => 'string', 'description' => 'street' },
                      'postcode' => { 'type' => 'string', 'description' => 'postcode' },
                      'city' => { 'type' => 'string', 'description' => 'city' },
                      'country' => { 'type' => 'string', 'description' => 'country' }
                    },
                    'required' => %w[street postcode city]
                  }
                }
              },
              'required' => %w[name]
            }
          },
          'description' => 'post in body with nested parameters'
        )
      end
    end

    describe 'PUT' do
      let(:endpoint) { subject['paths']['/simple_nested_params/in_body/{id}']['put'] }

      specify do
        expect(endpoint['parameters']).to eql(
          [{
            'in' => 'path', 'name' => 'id', 'schema' => { 'format' => 'int32', 'type' => 'integer' }, 'required' => true
          }]
        )

        expect(endpoint['requestBody']['content']['application/json']).to eql(
          'schema' => {
            'properties' => {
              'SimpleNestedParamsInBody' => {
                '$ref' => '#/components/schemas/putSimpleNestedParamsInBody'
              }
            }, 'required' => ['SimpleNestedParamsInBody'], 'type' => 'object'
          }
        )
      end

      specify do
        expect(subject['components']['schemas']['putSimpleNestedParamsInBody']).to eql(
          'type' => 'object',
          'properties' => {
            'name' => { 'type' => 'string', 'description' => 'name' },
            'address' => {
              'type' => 'object',
              'properties' => {
                'street' => { 'type' => 'string', 'description' => 'street' },
                'postcode' => { 'type' => 'string', 'description' => 'postcode' },
                'city' => { 'type' => 'string', 'description' => 'city' },
                'country' => { 'type' => 'string', 'description' => 'country' }
              }
            }
          },
          'description' => 'put in body with nested parameters'
        )
      end
    end
  end

  describe 'multiple nested body parameters given' do
    subject do
      get '/swagger_doc/multiple_nested_params'
      JSON.parse(last_response.body)
    end

    describe 'POST' do
      let(:endpoint) { subject['paths']['/multiple_nested_params/in_body']['post'] }

      specify do
        expect(endpoint['requestBody']['content']['application/json']).to eql(
          'schema' => {
            'properties' => {
              'MultipleNestedParamsInBody' => {
                '$ref' => '#/components/schemas/postMultipleNestedParamsInBody'
              }
            },
            'required' => ['MultipleNestedParamsInBody'],
            'type' => 'object'
          }
        )
      end

      specify do
        expect(subject['components']['schemas']['postMultipleNestedParamsInBody']).to eql(
          'type' => 'object',
          'properties' => {
            'contact' => {
              'type' => 'object',
              'properties' => {
                'name' => { 'type' => 'string', 'description' => 'name' },
                'addresses' => {
                  'type' => 'array',
                  'items' => {
                    'type' => 'object',
                    'properties' => {
                      'street' => { 'type' => 'string', 'description' => 'street' },
                      'postcode' => { 'type' => 'integer', 'format' => 'int32', 'description' => 'postcode' },
                      'city' => { 'type' => 'string', 'description' => 'city' },
                      'country' => { 'type' => 'string', 'description' => 'country' }
                    },
                    'required' => ['postcode']
                  }
                },
                'delivery_address' => {
                  'type' => 'object',
                  'properties' => {
                    'street' => { 'type' => 'string', 'description' => 'street' },
                    'postcode' => { 'type' => 'string', 'description' => 'postcode' },
                    'city' => { 'type' => 'string', 'description' => 'city' },
                    'country' => { 'type' => 'string', 'description' => 'country' }
                  }
                }
              },
              'required' => %w[name]
            }
          },
          'description' => 'put in body with multiple nested parameters'
        )
      end
    end

    describe 'PUT' do
      let(:endpoint) { subject['paths']['/multiple_nested_params/in_body/{id}']['put'] }

      specify do
        expect(endpoint['parameters']).to eql(
          [{
            'in' => 'path',
            'name' => 'id',
            'schema' => { 'format' => 'int32', 'type' => 'integer' },
            'required' => true
          }]
        )
        expect(endpoint['requestBody']['content']['application/json']).to eql(
          'schema' => {
            'properties' => {
              'MultipleNestedParamsInBody' => {
                '$ref' => '#/components/schemas/putMultipleNestedParamsInBody'
              }
            },
            'required' => ['MultipleNestedParamsInBody'],
            'type' => 'object'
          }
        )
      end

      specify do
        expect(subject['components']['schemas']['putMultipleNestedParamsInBody']).to eql(
          'type' => 'object',
          'properties' => {
            'name' => { 'type' => 'string', 'description' => 'name' },
            'address' => {
              'type' => 'object',
              'properties' => {
                'street' => { 'type' => 'string', 'description' => 'street' },
                'postcode' => { 'type' => 'string', 'description' => 'postcode' },
                'city' => { 'type' => 'string', 'description' => 'city' },
                'country' => { 'type' => 'string', 'description' => 'country' }
              },
              'required' => ['postcode']
            },
            'delivery_address' => {
              'type' => 'object',
              'properties' => {
                'street' => { 'type' => 'string', 'description' => 'street' },
                'postcode' => { 'type' => 'string', 'description' => 'postcode' },
                'city' => { 'type' => 'string', 'description' => 'city' },
                'country' => { 'type' => 'string', 'description' => 'country' }
              }
            }
          },
          'description' => 'put in body with multiple nested parameters'
        )
      end
    end
  end
end
