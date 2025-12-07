# frozen_string_literal: true

require 'spec_helper'

describe 'OAS 3.0 Group Params as Array' do
  include_context "#{MODEL_PARSER} swagger example"

  [true, false].each do |array_use_braces|
    context "when array_use_braces option is set to #{array_use_braces}" do
      let(:braces) { array_use_braces ? '[]' : '' }

      let(:app) do
        braces_setting = array_use_braces
        Class.new(Grape::API) do
          format :json

          params do
            requires :required_group, type: Array do
              requires :required_param_1
              requires :required_param_2
            end
          end
          post '/groups' do
            { 'declared_params' => declared(params) }
          end

          params do
            requires :typed_group, type: Array do
              requires :id, type: Integer, desc: 'integer given'
              requires :name, type: String, desc: 'string given'
              optional :email, type: String, desc: 'email given'
              optional :others, type: Integer, values: [1, 2, 3]
            end
          end
          post '/type_given' do
            { 'declared_params' => declared(params) }
          end

          params do
            requires :array_of_string, type: Array[String], documentation: { param_type: 'body', desc: 'nested array of strings' }
            requires :array_of_integer, type: Array[Integer], documentation: { param_type: 'body', desc: 'nested array of integers' }
          end
          post '/array_of_type' do
            { 'declared_params' => declared(params) }
          end

          params do
            requires :array_of_string, type: Array[String], documentation: { param_type: 'body', desc: 'array of strings' }
            requires :integer_value, type: Integer, documentation: { param_type: 'body', desc: 'integer value' }
          end
          post '/object_and_array' do
            { 'declared_params' => declared(params) }
          end

          params do
            requires :array_of_string, type: Array[String]
            requires :array_of_integer, type: Array[Integer]
          end
          post '/array_of_type_in_form' do
            { 'declared_params' => declared(params) }
          end

          params do
            requires :array_of_entities, type: Array[Entities::ApiError]
          end
          post '/array_of_entities' do
            { 'declared_params' => declared(params) }
          end

          add_swagger_documentation openapi_version: '3.0', array_use_braces: braces_setting
        end
      end

      describe 'grouped parameters' do
        subject do
          get '/swagger_doc/groups'
          JSON.parse(last_response.body)
        end

        it 'creates requestBody for grouped array parameters' do
          request_body = subject['paths']['/groups']['post']['requestBody']
          expect(request_body).to be_present
          expect(request_body['content']).to be_present
        end

        it 'has array type properties for group members in component schema' do
          # Our implementation uses $ref to reference schemas
          schemas = subject['components']['schemas']
          schema = schemas['postGroups']

          expect(schema['type']).to eq('object')
          expect(schema['properties']).to be_present
          expect(schema['properties']['required_group']['type']).to eq('array')
        end
      end

      describe 'typed group parameters' do
        subject do
          get '/swagger_doc/type_given'
          JSON.parse(last_response.body)
        end

        it 'creates requestBody with schema' do
          request_body = subject['paths']['/type_given']['post']['requestBody']
          expect(request_body).to be_present
        end

        it 'has typed_group as array in component schema' do
          schemas = subject['components']['schemas']
          schema = schemas['postTypeGiven']

          expect(schema['type']).to eq('object')
          expect(schema['properties']['typed_group']['type']).to eq('array')
        end
      end

      describe 'array of primitive types in body' do
        subject do
          get '/swagger_doc/array_of_type'
          JSON.parse(last_response.body)
        end

        it 'creates object schema in components with array properties' do
          schemas = subject['components']['schemas']
          schema = schemas['postArrayOfType']

          expect(schema).to be_present
          expect(schema['type']).to eq('object')
          expect(schema['properties']['array_of_string']['type']).to eq('array')
          expect(schema['properties']['array_of_integer']['type']).to eq('array')
        end

        it 'has items with correct primitive types' do
          schemas = subject['components']['schemas']
          schema = schemas['postArrayOfType']

          expect(schema['properties']['array_of_string']['items']['type']).to eq('string')
          expect(schema['properties']['array_of_integer']['items']['type']).to eq('integer')
        end

        it 'includes descriptions for array properties' do
          schemas = subject['components']['schemas']
          schema = schemas['postArrayOfType']

          expect(schema['properties']['array_of_string']['description']).to eq('nested array of strings')
          expect(schema['properties']['array_of_integer']['description']).to eq('nested array of integers')
        end
      end

      describe 'mixed object and array parameters' do
        subject do
          get '/swagger_doc/object_and_array'
          JSON.parse(last_response.body)
        end

        it 'creates object schema with array property' do
          schemas = subject['components']['schemas']
          schema = schemas['postObjectAndArray']

          expect(schema['type']).to eq('object')
          expect(schema['properties']['array_of_string']['type']).to eq('array')
          expect(schema['properties']['integer_value']['type']).to eq('integer')
        end
      end

      describe 'array of type in form' do
        subject do
          get '/swagger_doc/array_of_type_in_form'
          JSON.parse(last_response.body)
        end

        it 'creates requestBody with content' do
          request_body = subject['paths']['/array_of_type_in_form']['post']['requestBody']
          expect(request_body['content']).to be_present
        end

        it 'has array properties in component schema' do
          schemas = subject['components']['schemas']
          schema = schemas['postArrayOfTypeInForm']

          expect(schema['properties']).to be_present
          expect(schema['properties']['array_of_string']['type']).to eq('array')
          expect(schema['properties']['array_of_integer']['type']).to eq('array')
        end
      end

      describe 'array of entities' do
        subject do
          get '/swagger_doc/array_of_entities'
          JSON.parse(last_response.body)
        end

        it 'includes entity schema in components' do
          expect(subject['components']['schemas']['ApiError']).to be_present
        end

        it 'has array property in component schema' do
          schemas = subject['components']['schemas']
          schema = schemas['postArrayOfEntities']

          expect(schema['properties']['array_of_entities']['type']).to eq('array')
        end
      end
    end
  end
end
