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

          add_swagger_documentation array_use_braces: array_use_braces
        end
      end

      describe 'retrieves the documentation for grouped parameters' do
        subject do
          get '/swagger_doc/groups'
          JSON.parse(last_response.body)
        end

        specify do
          expect(subject['paths']['/groups']['post']['parameters']).to eql(
            [
              { 'in' => 'formData', 'name' => "required_group#{braces}[required_param_1]", 'required' => true, 'type' => 'array', 'items' => { 'type' => 'string' } },
              { 'in' => 'formData', 'name' => "required_group#{braces}[required_param_2]", 'required' => true, 'type' => 'array', 'items' => { 'type' => 'string' } }
            ]
          )
        end
      end

      describe 'retrieves the documentation for typed group parameters' do
        subject do
          get '/swagger_doc/type_given'
          JSON.parse(last_response.body)
        end

        specify do
          expect(subject['paths']['/type_given']['post']['parameters']).to eql(
            [
              { 'in' => 'formData', 'name' => "typed_group#{braces}[id]", 'description' => 'integer given', 'type' => 'array', 'items' => { 'type' => 'integer', 'format' => 'int32' }, 'required' => true },
              { 'in' => 'formData', 'name' => "typed_group#{braces}[name]", 'description' => 'string given', 'type' => 'array', 'items' => { 'type' => 'string' }, 'required' => true },
              { 'in' => 'formData', 'name' => "typed_group#{braces}[email]", 'description' => 'email given', 'type' => 'array', 'items' => { 'type' => 'string' }, 'required' => false },
              { 'in' => 'formData', 'name' => "typed_group#{braces}[others]", 'type' => 'array', 'items' => { 'type' => 'integer', 'format' => 'int32', 'enum' => [1, 2, 3] }, 'required' => false }
            ]
          )
        end
      end

      describe 'retrieves the documentation for parameters that are arrays of primitive types' do
        subject do
          get '/swagger_doc/array_of_type'
          JSON.parse(last_response.body)
        end

        specify do
          expect(subject['definitions']['postArrayOfType']['type']).to eql 'array'
          expect(subject['definitions']['postArrayOfType']['items']).to eql(
            'type' => 'object',
            'properties' => {
              'array_of_string' => {
                'items' => { 'type' => 'string' }, 'type' => 'array', 'description' => 'nested array of strings'
              },
              'array_of_integer' => {
                'items' => { 'type' => 'integer', 'format' => 'int32' }, 'type' => 'array', 'description' => 'nested array of integers'
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
          expect(subject['definitions']['postObjectAndArray']['type']).to eql 'object'
          expect(subject['definitions']['postObjectAndArray']['properties']).to eql(
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
          expect(subject['paths']['/array_of_type_in_form']['post']['parameters']).to eql(
            [
              { 'in' => 'formData', 'name' => "array_of_string#{braces}", 'type' => 'array', 'items' => { 'type' => 'string' }, 'required' => true },
              { 'in' => 'formData', 'name' => "array_of_integer#{braces}", 'type' => 'array', 'items' => { 'type' => 'integer', 'format' => 'int32' }, 'required' => true }
            ]
          )
        end
      end

      describe 'documentation for entity array parameters' do
        let(:parameters) do
          [
            {
              'in' => 'formData',
              'name' => "array_of_entities#{braces}",
              'type' => 'array',
              'items' => {
                '$ref' => '#/definitions/ApiError'
              },
              'required' => true
            }
          ]
        end

        subject do
          get '/swagger_doc/array_of_entities'
          JSON.parse(last_response.body)
        end

        specify do
          expect(subject['definitions']['ApiError']).not_to be_blank
          expect(subject['paths']['/array_of_entities']['post']['parameters']).to eql(parameters)
        end
      end
    end
  end
end
