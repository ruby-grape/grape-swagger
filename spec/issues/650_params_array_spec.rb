# frozen_string_literal: true

require 'spec_helper'

describe '#605 Group Params as Array' do
  let(:app) do
    Class.new(Grape::API) do
      params do
        requires :array_of_range_string, type: [String], values: %w[a b c]
        requires :array_of_range_integer, type: [Integer], values: [1, 2, 3]
      end
      post '/array_of_range' do
        { 'declared_params' => declared(params) }
      end

      params do
        requires :array_with_default_string, type: [String], default: 'abc'
        requires :array_with_default_integer, type: Array[Integer], default: 123
      end
      post '/array_with_default' do
        { 'declared_params' => declared(params) }
      end

      add_swagger_documentation
    end
  end

  describe 'retrieves the documentation for typed group range parameters' do
    subject do
      get '/swagger_doc/array_of_range'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/array_of_range']['post']['parameters']).to eql(
        [
          { 'in' => 'formData', 'name' => 'array_of_range_string', 'type' => 'array', 'items' => { 'type' => 'string', 'enum' => %w[a b c] }, 'required' => true },
          { 'in' => 'formData', 'name' => 'array_of_range_integer', 'type' => 'array', 'items' => { 'type' => 'integer', 'format' => 'int32', 'enum' => [1, 2, 3] }, 'required' => true }
        ]
      )
    end
  end

  describe 'retrieves the documentation for typed group parameters with default' do
    subject do
      get '/swagger_doc/array_with_default'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/array_with_default']['post']['parameters']).to eql(
        [
          { 'in' => 'formData', 'name' => 'array_with_default_string', 'type' => 'array', 'items' => { 'type' => 'string', 'default' => 'abc' }, 'required' => true },
          { 'in' => 'formData', 'name' => 'array_with_default_integer', 'type' => 'array', 'items' => { 'type' => 'integer', 'format' => 'int32', 'default' => 123 }, 'required' => true }
        ]
      )
    end
  end
end
