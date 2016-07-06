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
            requires :name, type: String, documentation: { desc: 'name', in: 'body' }
            optional :addresses, type: Array do
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
            optional :name, type: String, documentation: { desc: 'name', in: 'body' }
            optional :addresses, type: Array do
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
        [
          { 'name' => 'SimpleNestedParamsInBody', 'in' => 'body', 'required' => true, 'schema' => { '$ref' => '#/definitions/postSimpleNestedParamsInBody' } }
        ]
      )
    end

    specify do
      expect(subject['definitions']['postSimpleNestedParamsInBody']).to eql(
        'type' => 'object',
        'properties' => {
          'addresses' => { 'type' => 'array', 'items' => { '$ref' => '#/definitions/postSimpleNestedParamsInBodyAddresses' } },
          'name' => { 'type' => 'string', 'description' => 'name' }
        },
        'required' => ['name'],
        'description' => 'post in body with nested parameters'
      )
      expect(subject['definitions']['postSimpleNestedParamsInBodyAddresses']).to eql(
        'type' => 'object',
        'properties' => {
          'street' => { 'type' => 'string', 'description' => 'street' },
          'postcode' => { 'type' => 'string', 'description' => 'postcode' },
          'city' => { 'type' => 'string', 'description' => 'city' },
          'country' => { 'type' => 'string', 'description' => 'country' }
        },
        'required' => %w(street postcode city),
        'description' => 'postSimpleNestedParamsInBody - addresses'
      )
    end

    specify do
      expect(subject['paths']['/simple_nested_params/in_body/{id}']['put']['parameters']).to eql(
        [
          { 'in' => 'path', 'name' => 'id', 'type' => 'integer', 'format' => 'int32', 'required' => true },
          { 'name' => 'SimpleNestedParamsInBody', 'in' => 'body', 'required' => true, 'schema' => { '$ref' => '#/definitions/putSimpleNestedParamsInBody' } }
        ]
      )
    end

    specify do
      expect(subject['definitions']['putSimpleNestedParamsInBody']).to eql(
        'type' => 'object',
        'properties' =>  {
          'address' => { '$ref' => '#/definitions/putSimpleNestedParamsInBodyAddress' },
          'name' => { 'type' => 'string', 'description' => 'name' }
        },
        'description' => 'put in body with nested parameters'
      )
      expect(subject['definitions']['putSimpleNestedParamsInBodyAddress']).to eql(
        'type' => 'object',
        'properties' => {
          'street' => { 'type' => 'string', 'description' => 'street' },
          'postcode' => { 'type' => 'string', 'description' => 'postcode' },
          'city' => { 'type' => 'string', 'description' => 'city' },
          'country' => { 'type' => 'string', 'description' => 'country' }
        },
        'description' => 'putSimpleNestedParamsInBody - address'
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
          { 'name' => 'MultipleNestedParamsInBody', 'in' => 'body', 'required' => true, 'schema' => { '$ref' => '#/definitions/putMultipleNestedParamsInBody' } }
        ]
      )
    end

    specify do
      expect(subject['definitions']['putMultipleNestedParamsInBody']).to eql(
        'type' => 'object',
        'properties' =>  {
          'address' => { '$ref' => '#/definitions/putMultipleNestedParamsInBodyAddress' },
          'delivery_address' => { '$ref' => '#/definitions/putMultipleNestedParamsInBodyDeliveryAddress' },
          'name' => { 'type' => 'string', 'description' => 'name' }
        },
        'description' => 'put in body with multiple nested parameters'
      )
      expect(subject['definitions']['putMultipleNestedParamsInBodyAddress']).to eql(
        'type' => 'object',
        'properties' => {
          'street' => { 'type' => 'string', 'description' => 'street' },
          'postcode' => { 'type' => 'string', 'description' => 'postcode' },
          'city' => { 'type' => 'string', 'description' => 'city' },
          'country' => { 'type' => 'string', 'description' => 'country' }
        },
        'required' => ['postcode'],
        'description' => 'putMultipleNestedParamsInBody - address'
      )
      expect(subject['definitions']['putMultipleNestedParamsInBodyDeliveryAddress']).to eql(
        'type' => 'object',
        'properties' => {
          'street' => { 'type' => 'string', 'description' => 'street' },
          'postcode' => { 'type' => 'string', 'description' => 'postcode' },
          'city' => { 'type' => 'string', 'description' => 'city' },
          'country' => { 'type' => 'string', 'description' => 'country' }
        },
        'description' => 'putMultipleNestedParamsInBody - delivery_address'
      )
    end
  end
end
