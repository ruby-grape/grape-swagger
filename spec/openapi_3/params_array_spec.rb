# frozen_string_literal: true

require 'spec_helper'

describe 'Group Params as Array' do
  include_context "#{MODEL_PARSER} swagger example"

  [true, false].each do |array_use_braces|
    context "when array_use_braces option is set to #{array_use_braces}" do
      let(:braces) { array_use_braces ? '[]' : '' }

      let(:app) do
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

          # as body parameters it would be interpreted a bit different,
          # cause it could not be distinguished anymore, so this would be translated to one array,
          # see also next example for the difference
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

          add_swagger_documentation openapi_version: '3.0', array_use_braces: array_use_braces
        end
      end

      describe 'retrieves the documentation for grouped parameters' do
        subject do
          get '/swagger_doc/groups'
          JSON.parse(last_response.body)
        end

        specify do
          expect(subject['paths']['/groups']['post']['requestBody']['content']['application/json']).to eql(
            'schema' => {
              'properties' => {
                "required_group#{braces}[required_param_1]" => { 'items' => { 'type' => 'string' }, 'type' => 'array' },
                "required_group#{braces}[required_param_2]" => { 'items' => { 'type' => 'string' }, 'type' => 'array' }
              },
              'required' => %W[required_group#{braces}[required_param_1] required_group#{braces}[required_param_2]],
              'type' => 'object'
            }
          )
        end
      end

      describe 'retrieves the documentation for typed group parameters' do
        subject do
          get '/swagger_doc/type_given'
          JSON.parse(last_response.body)
        end

        specify do
          expect(subject['paths']['/type_given']['post']['requestBody']['content']['application/x-www-form-urlencoded']).to eql(
            'schema' => {
              'properties' => {
                "typed_group#{braces}[email]" => {
                  'description' => 'email given',
                  'items' => { 'type' => 'string' },
                  'type' => 'array'
                },
                "typed_group#{braces}[id]" => {
                  'description' => 'integer given',
                  'format' => 'int32',
                  'items' => { 'type' => 'integer' },
                  'type' => 'array'
                },
                "typed_group#{braces}[name]" => {
                  'description' => 'string given',
                  'items' => { 'type' => 'string' },
                  'type' => 'array'
                },
                "typed_group#{braces}[others]" => {
                  'format' => 'int32',
                  'items' => { 'enum' => [1, 2, 3], 'type' => 'integer' },
                  'type' => 'array'
                }
              },
              'required' => %W[typed_group#{braces}[id] typed_group#{braces}[name]], 'type' => 'object'
            }
          )
        end
      end

      describe 'retrieves the documentation for parameters that are arrays of primitive types' do
        subject do
          get '/swagger_doc/array_of_type'
          JSON.parse(last_response.body)
        end

        specify do
          expect(subject['components']['schemas']['postArrayOfType']['type']).to eql 'array'
          expect(subject['components']['schemas']['postArrayOfType']['items']).to eql(
            'type' => 'object',
            'properties' => {
              'array_of_string' => {
                'type' => 'string', 'description' => 'nested array of strings'
              },
              'array_of_integer' => {
                'type' => 'integer', 'format' => 'int32', 'description' => 'nested array of integers'
              }
            },
            'required' => %w[array_of_string array_of_integer]
          )
        end
      end

      describe 'documentation for simple and array parameters' do
        subject do
          get '/swagger_doc/object_and_array'
          JSON.parse(last_response.body)
        end

        specify do
          expect(subject['components']['schemas']['postObjectAndArray']['type']).to eql 'object'
          expect(subject['components']['schemas']['postObjectAndArray']['properties']).to eql(
            'array_of_string' => {
              'type' => 'array',
              'description' => 'array of strings',
              'items' => {
                'type' => 'string'
              }
            },
            'integer_value' => {
              'type' => 'integer', 'format' => 'int32', 'description' => 'integer value'
            }
          )
        end
      end

      describe 'retrieves the documentation for typed group parameters' do
        subject do
          get '/swagger_doc/array_of_type_in_form'
          JSON.parse(last_response.body)
        end

        specify do
          expect(subject['paths']['/array_of_type_in_form']['post']['requestBody']['content']['application/x-www-form-urlencoded']).to eql(
            'schema' => {
              'properties' => {
                "array_of_integer#{braces}" => { 'format' => 'int32', 'items' => { 'type' => 'integer' }, 'type' => 'array' },
                "array_of_string#{braces}" => { 'items' => { 'type' => 'string' }, 'type' => 'array' }
              },
              'required' => %W[array_of_string#{braces} array_of_integer#{braces}],
              'type' => 'object'
            }
          )
        end
      end

      describe 'documentation for entity array parameters' do
        let(:parameters) do
          {
            'properties' => {
              "array_of_entities#{braces}" => {
                'items' => { '$ref' => '#/components/schemas/ApiError' },
                'type' => 'array'
              }
            },
            'required' => ["array_of_entities#{braces}"], 'type' => 'object'
          }
        end

        subject do
          get '/swagger_doc/array_of_entities'
          JSON.parse(last_response.body)
        end

        specify do
          expect(subject['components']['schemas']['ApiError']).not_to be_blank
          expect(subject['paths']['/array_of_entities']['post']['requestBody']['content']['application/x-www-form-urlencoded']['schema']).to eql(parameters)
        end
      end
    end
  end
end
