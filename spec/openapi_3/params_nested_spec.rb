# frozen_string_literal: true

require 'spec_helper'

describe 'nested group params' do
  [true, false].each do |array_use_braces|
    context "when array_use_braces option is set to #{array_use_braces}" do
      let(:braces) { array_use_braces ? '[]' : '' }
      let(:app) do
        Class.new(Grape::API) do
          format :json

          params do
            requires :a_array, type: Array do
              requires :param_1, type: Integer
              requires :b_array, type: Array do
                requires :param_2, type: String
              end
              requires :c_hash, type: Hash do
                requires :param_3, type: String
              end
            end
            requires :a_array_foo, type: String
          end
          post '/nested_array' do
            { 'declared_params' => declared(params) }
          end

          params do
            requires :a_hash, type: Hash do
              requires :param_1, type: Integer
              requires :b_hash, type: Hash do
                requires :param_2, type: String
              end
              requires :c_array, type: Array do
                requires :param_3, type: String
              end
            end
            requires :a_hash_foo, type: String
          end
          post '/nested_hash' do
            { 'declared_params' => declared(params) }
          end

          add_swagger_documentation openapi_version: '3.0', array_use_braces: array_use_braces
        end
      end

      describe 'retrieves the documentation for nested array parameters' do
        subject do
          get '/swagger_doc/nested_array'
          JSON.parse(last_response.body)
        end

        specify do
          expect(subject['paths']['/nested_array']['post']['requestBody']['content']['application/x-www-form-urlencoded']).to eql(
            'schema' => {
              'properties' => {
                "a_array#{braces}[b_array]#{braces}[param_2]" => { 'items' => { 'type' => 'string' }, 'type' => 'array' },
                "a_array#{braces}[c_hash][param_3]" => { 'items' => { 'type' => 'string' }, 'type' => 'array' },
                "a_array#{braces}[param_1]" => { 'format' => 'int32', 'items' => { 'type' => 'integer' }, 'type' => 'array' },
                'a_array_foo' => { 'type' => 'string' }
              },
              'required' => ["a_array#{braces}[param_1]",
                             "a_array#{braces}[b_array]#{braces}[param_2]",
                             "a_array#{braces}[c_hash][param_3]",
                             'a_array_foo'],
              'type' => 'object'
            }
          )
        end
      end

      describe 'retrieves the documentation for nested hash parameters' do
        subject do
          get '/swagger_doc/nested_hash'
          JSON.parse(last_response.body)
        end

        specify do
          expect(subject['paths']['/nested_hash']['post']['requestBody']['content']['application/x-www-form-urlencoded']).to eql(
            'schema' => {
              'properties' => {
                'a_hash[b_hash][param_2]' => { 'type' => 'string' },
                "a_hash[c_array]#{braces}[param_3]" => { 'items' => { 'type' => 'string' }, 'type' => 'array' },
                'a_hash[param_1]' => { 'format' => 'int32', 'type' => 'integer' },
                'a_hash_foo' => { 'type' => 'string' }
              },
              'required' => ['a_hash[param_1]',
                             'a_hash[b_hash][param_2]',
                             "a_hash[c_array]#{braces}[param_3]",
                             'a_hash_foo'],
              'type' => 'object'
            }
          )
        end
      end
    end
  end
end
