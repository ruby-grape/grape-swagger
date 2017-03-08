# frozen_string_literal: true
require 'spec_helper'

describe 'nested group params' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :a_array, type: Array do
          requires :param_1, type: Integer
          requires :b_array, type: Array do
            requires :param_2, type: String
          end
        end
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
        end
      end
      post '/nested_hash' do
        { 'declared_params' => declared(params) }
      end

      add_swagger_documentation
    end
  end

  describe 'retrieves the documentation for nested array parameters' do
    subject do
      get '/swagger_doc/nested_array'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/nested_array']['post']['parameters']).to eql(
        [
          { 'in' => 'formData', 'name' => 'a_array[param_1]', 'required' => true, 'type' => 'array', 'items' => { 'type' => 'integer', 'format' => 'int32' } },
          { 'in' => 'formData', 'name' => 'a_array[b_array][param_2]', 'required' => true, 'type' => 'array', 'items' => { 'type' => 'string' } }
        ]
      )
    end
  end

  describe 'retrieves the documentation for nested hash parameters' do
    subject do
      get '/swagger_doc/nested_hash'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/nested_hash']['post']['parameters']).to eql(
        [
          { 'in' => 'formData', 'name' => 'a_hash[param_1]', 'required' => true, 'type' => 'integer', 'format' => 'int32' },
          { 'in' => 'formData', 'name' => 'a_hash[b_hash][param_2]', 'required' => true, 'type' => 'string' }
        ]
      )
    end
  end
end
