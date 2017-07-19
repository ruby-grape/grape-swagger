# frozen_string_literal: true

require 'spec_helper'

describe 'Group Array Params, using collection format' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        optional :array_of_strings, type: Array[String], desc: 'array in csv collection format'
      end

      get '/array_of_strings_without_collection_format' do
        { 'declared_params' => declared(params) }
      end

      params do
        optional :array_of_strings, type: Array[String], desc: 'array in multi collection format', documentation: { collectionFormat: 'multi' }
      end

      get '/array_of_strings_multi_collection_format' do
        { 'declared_params' => declared(params) }
      end

      params do
        optional :array_of_strings, type: Array[String], documentation: { collectionFormat: 'foo' }
      end

      get '/array_of_strings_invalid_collection_format' do
        { 'declared_params' => declared(params) }
      end

      params do
        optional :array_of_strings, type: Array[String], desc: 'array in brackets collection format', documentation: { collectionFormat: 'brackets' }
      end

      get '/array_of_strings_brackets_collection_format' do
        { 'declared_params' => declared(params) }
      end

      add_swagger_documentation
    end
  end

  describe 'documentation for array parameter in default csv collectionFormat' do
    subject do
      get '/swagger_doc/array_of_strings_without_collection_format'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/array_of_strings_without_collection_format']['get']['parameters']).to eql(
        [
          { 'in' => 'formData', 'name' => 'array_of_strings', 'type' => 'array', 'items' => { 'type' => 'string' }, 'required' => false, 'description' => 'array in csv collection format' }
        ]
      )
    end
  end

  describe 'documentation for array parameters in multi collectionFormat set from documentation' do
    subject do
      get '/swagger_doc/array_of_strings_multi_collection_format'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/array_of_strings_multi_collection_format']['get']['parameters']).to eql(
        [
          { 'in' => 'formData', 'name' => 'array_of_strings', 'type' => 'array', 'items' => { 'type' => 'string' }, 'required' => false, 'collectionFormat' => 'multi', 'description' => 'array in multi collection format' }
        ]
      )
    end
  end

  describe 'documentation for array parameters in brackets collectionFormat set from documentation' do
    subject do
      get '/swagger_doc/array_of_strings_brackets_collection_format'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/array_of_strings_brackets_collection_format']['get']['parameters']).to eql(
        [
          { 'in' => 'formData', 'name' => 'array_of_strings', 'type' => 'array', 'items' => { 'type' => 'string' }, 'required' => false, 'collectionFormat' => 'brackets', 'description' => 'array in brackets collection format' }
        ]
      )
    end
  end

  describe 'documentation for array parameters with collectionFormat set to invalid option' do
    subject do
      get '/swagger_doc/array_of_strings_invalid_collection_format'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/array_of_strings_invalid_collection_format']['get']['parameters']).to eql(
        [
          { 'in' => 'formData', 'name' => 'array_of_strings', 'type' => 'array', 'items' => { 'type' => 'string' }, 'required' => false }
        ]
      )
    end
  end
end
