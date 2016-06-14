require 'spec_helper'

describe 'setting of param type, such as `query`, `path`, `formData`, `body`, `header`' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class NestedBodyParamTypeApi < Grape::API
        namespace :simple_nested_params do
          desc 'post in body with nested parameters',
               detail: 'more details description',
               success: Entities::UseNestedWithAddress
          params do
            requires :name, type: String, documentation: { desc: 'name', in: 'body' }
            optional :address, type: Hash do
              requires :street, type: String, documentation: { desc: 'street', in: 'body' }
              requires :postcode, type: String, documentation: { desc: 'postcode', in: 'body' }
              requires :city, type: String, documentation: { desc: 'city', in: 'body' }
              optional :country, type: String, documentation: { desc: 'country', in: 'body' }
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

    specify do
      expect(subject['paths']['/simple_nested_params/in_body']['post']['parameters']).to eql(
        [{
          'name' => 'UseNestedWithAddress',
          'in' => 'body',
          'required' => true,
          'schema' => { '$ref' => '#/definitions/postRequestUseNestedWithAddress' }
        }]
      )
    end

    specify do
      expect(subject['definitions']['postRequestUseNestedWithAddress']).to eql(
        'description' => "post in body with nested parameters\n more details description",
        'type' => 'object',
        'properties' => {
          'address' => { '$ref' => '#/definitions/postRequestUseNestedWithAddressAddress' },
          'name' => { 'type' => 'string', 'description' => 'name' }
        },
        'required' => ['name']
      )
      expect(subject['definitions']['postRequestUseNestedWithAddressAddress']).to eql(
        'description' => 'postRequestUseNestedWithAddress - address',
        'type' => 'object',
        'properties' => {
          'street' => { 'type' => 'string', 'description' => 'street' },
          'postcode' => { 'type' => 'string', 'description' => 'postcode' },
          'city' => { 'type' => 'string', 'description' => 'city' },
          'country' => { 'type' => 'string', 'description' => 'country' }
        },
        'required' => %w(street postcode city)
      )
    end

    specify do
      expect(subject['paths']['/simple_nested_params/in_body/{id}']['put']['parameters']).to eql(
        [
          { 'in' => 'path', 'name' => 'id', 'type' => 'integer', 'format' => 'int32', 'required' => true },
          {
            'name' => 'UseNestedWithAddress',
            'in' => 'body',
            'required' => true,
            'schema' => { '$ref' => '#/definitions/putRequestUseNestedWithAddress' }
          }
        ]
      )
    end

    specify do
      expect(subject['definitions']['putRequestUseNestedWithAddress']).to eql(
        'description' => "put in body with nested parameters\n more details description",
        'type' => 'object',
        'properties' => {
          'address' => { '$ref' => '#/definitions/putRequestUseNestedWithAddressAddress' },
          'name' => { 'type' => 'string', 'description' => 'name' }
        }
      )
      expect(subject['definitions']['putRequestUseNestedWithAddressAddress']).to eql(
        'description' => 'putRequestUseNestedWithAddress - address',
        'type' => 'object',
        'properties' => {
          'street' => { 'type' => 'string', 'description' => 'street' },
          'postcode' => { 'type' => 'string', 'description' => 'postcode' },
          'city' => { 'type' => 'string', 'description' => 'city' },
          'country' => { 'type' => 'string', 'description' => 'country' }
        }
      )
    end
  end

  describe 'multiple nested body parameters given' do
    subject do
      get '/swagger_doc/multiple_nested_params'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/multiple_nested_params/in_body/{id}']['put']['parameters']).to eql(
        [
          { 'in' => 'path', 'name' => 'id', 'type' => 'integer', 'format' => 'int32', 'required' => true },
          { 'name' => 'UseNestedWithAddress', 'in' => 'body', 'required' => true, 'schema' => { '$ref' => '#/definitions/putRequestUseNestedWithAddress' } }
        ]
      )
    end

    specify do
      expect(subject['definitions']['putRequestUseNestedWithAddress']).to eql(
        'description' => 'put in body with multiple nested parameters',
        'type' => 'object',
        'properties' => {
          'address' => { '$ref' => '#/definitions/putRequestUseNestedWithAddressAddress' },
          'delivery_address' => { '$ref' => '#/definitions/putRequestUseNestedWithAddressDeliveryAddress' },
          'name' => { 'type' => 'string', 'description' => 'name' }
        }
      )
      expect(subject['definitions']['putRequestUseNestedWithAddressAddress']).to eql(
        'description' => 'putRequestUseNestedWithAddress - address',
        'type' => 'object',
        'properties' => {
          'street' => { 'type' => 'string', 'description' => 'street' },
          'postcode' => { 'type' => 'string', 'description' => 'postcode' },
          'city' => { 'type' => 'string', 'description' => 'city' },
          'country' => { 'type' => 'string', 'description' => 'country' }
        },
        'required' => ['postcode']
      )
      expect(subject['definitions']['putRequestUseNestedWithAddressDeliveryAddress']).to eql(
        'description' => 'putRequestUseNestedWithAddress - delivery_address',
        'type' => 'object',
        'properties' => {
          'street' => { 'type' => 'string', 'description' => 'street' },
          'postcode' => { 'type' => 'string', 'description' => 'postcode' },
          'city' => { 'type' => 'string', 'description' => 'city' },
          'country' => { 'type' => 'string', 'description' => 'country' }
        }
      )
    end
  end
end
