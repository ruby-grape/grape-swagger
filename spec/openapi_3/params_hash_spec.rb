# frozen_string_literal: true

require 'spec_helper'

describe 'Group Params as Hash' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :required_group, type: Hash do
          requires :required_param_1
          requires :required_param_2
        end
      end
      post '/use_groups' do
        { 'declared_params' => declared(params) }
      end

      params do
        requires :typed_group, type: Hash do
          requires :id, type: Integer, desc: 'integer given'
          requires :name, type: String, desc: 'string given'
          optional :email, type: String, desc: 'email given'
          optional :others, type: Integer, values: [1, 2, 3]
        end
      end
      post '/use_given_type' do
        { 'declared_params' => declared(params) }
      end

      add_swagger_documentation openapi_version: '3.0'
    end
  end

  describe 'grouped parameters' do
    subject do
      get '/swagger_doc/use_groups'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/use_groups']['post']).to include('requestBody')
      expect(subject['paths']['/use_groups']['post']['requestBody']['content']).to eql(
        'application/json' => { 'schema' => { 'properties' => {}, 'type' => 'object' } },
        'application/x-www-form-urlencoded' => {
          'schema' => {
            'properties' => {
              'required_group[required_param_1]' => { 'type' => 'string' },
              'required_group[required_param_2]' => { 'type' => 'string' }
            },
            'required' => %w(required_group[required_param_1] required_group[required_param_2]),
            'type' => 'object'
          }
        }
      )
    end
  end

  describe 'grouped parameters with given type' do
    subject do
      get '/swagger_doc/use_given_type'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/use_given_type']['post']).to include('requestBody')
      expect(subject['paths']['/use_given_type']['post']['requestBody']['content']).to eql(
        'application/json' => { 'schema' => { 'properties' => {}, 'type' => 'object' } },
        'application/x-www-form-urlencoded' => {
          'schema' => {
            'properties' => {
              'typed_group[email]' => { 'description' => 'email given', 'type' => 'string' },
              'typed_group[id]' => { 'description' => 'integer given', 'format' => 'int32', 'type' => 'integer' },
              'typed_group[name]' => { 'description' => 'string given', 'type' => 'string' },
              'typed_group[others]' => { 'enum' => [1, 2, 3], 'format' => 'int32', 'type' => 'integer' }
            },
            'required' => ['typed_group[id]', 'typed_group[name]'],
            'type' => 'object'
          }
        }
      )
    end
  end
end
