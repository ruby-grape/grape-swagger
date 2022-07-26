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

        add_swagger_documentation
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
      specify do
        expect(subject['paths']['/simple_nested_params/in_body']['post']['parameters']).to eql(
          [
            { 'name' => 'postSimpleNestedParamsInBody', 'in' => 'body', 'required' => true, 'schema' => { '$ref' => '#/definitions/postSimpleNestedParamsInBody' } }
          ]
        )
      end

      specify do
        expect(subject['definitions']['postSimpleNestedParamsInBody']).to eql(
          'type' => 'object',
          'properties' => {
            'contact' => {
              'type' => 'object',
              'additionalProperties' => true,
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
      specify do
        expect(subject['paths']['/simple_nested_params/in_body/{id}']['put']['parameters']).to eql(
          [
            { 'in' => 'path', 'name' => 'id', 'type' => 'integer', 'format' => 'int32', 'required' => true },
            { 'name' => 'putSimpleNestedParamsInBodyId', 'in' => 'body', 'required' => true, 'schema' => { '$ref' => '#/definitions/putSimpleNestedParamsInBodyId' } }
          ]
        )
      end

      specify do
        expect(subject['definitions']['putSimpleNestedParamsInBodyId']).to eql(
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
      specify do
        expect(subject['paths']['/multiple_nested_params/in_body']['post']['parameters']).to eql(
          [
            {
              'name' => 'postMultipleNestedParamsInBody',
              'in' => 'body',
              'required' => true,
              'schema' => { '$ref' => '#/definitions/postMultipleNestedParamsInBody' }
            }
          ]
        )
      end

      specify do
        expect(subject['definitions']['postMultipleNestedParamsInBody']).to eql(
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
      specify do
        expect(subject['paths']['/multiple_nested_params/in_body/{id}']['put']['parameters']).to eql(
          [
            { 'in' => 'path', 'name' => 'id', 'type' => 'integer', 'format' => 'int32', 'required' => true },
            { 'name' => 'putMultipleNestedParamsInBodyId', 'in' => 'body', 'required' => true, 'schema' => { '$ref' => '#/definitions/putMultipleNestedParamsInBodyId' } }
          ]
        )
      end

      specify do
        expect(subject['definitions']['putMultipleNestedParamsInBodyId']).to eql(
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

  describe 'array of nested body parameters given' do
    subject do
      get '/swagger_doc/nested_params_array'
      JSON.parse(last_response.body)
    end

    describe 'POST' do
      specify do
        expect(subject['paths']['/nested_params_array/in_body']['post']['parameters']).to eql(
          [
            { 'name' => 'postNestedParamsArrayInBody', 'in' => 'body', 'required' => true, 'schema' => { '$ref' => '#/definitions/postNestedParamsArrayInBody' } }
          ]
        )
      end

      specify do
        expect(subject['definitions']['postNestedParamsArrayInBody']).to eql(
          'type' => 'object',
          'properties' => {
            'contacts' => {
              'type' => 'array',
              'items' => {
                'type' => 'object',
                'additionalProperties' => false,
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
            }
          },
          'description' => 'post in body with array of nested parameters'
        )
      end
    end
  end
end
