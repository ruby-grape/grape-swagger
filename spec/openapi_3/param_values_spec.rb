# frozen_string_literal: true

require 'spec_helper'
# require 'grape_version'

describe 'Convert values to enum or Range' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :letter, type: String, values: %w[a b c]
      end
      post :plain_array do
      end

      params do
        requires :letter, type: String, values: proc { %w[d e f] }
      end
      post :array_in_proc do
      end

      params do
        requires :letter, type: String, values: 'a'..'z'
      end
      post :range_letter do
      end

      params do
        requires :integer, type: Integer, values: -5..5
      end
      post :range_integer do
      end

      add_swagger_documentation openapi_version: '3.0'
    end
  end

  def first_parameter_info(request)
    get "/swagger_doc/#{request}"
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    body['paths']["/#{request}"]['post']['requestBody']['content']['application/x-www-form-urlencoded']['schema']
  end

  context 'Plain array values' do
    subject(:plain_array) { first_parameter_info('plain_array') }
    it 'has values as array in enum' do
      expect(plain_array).to eq(
        'properties' => {
          'letter' => {
            'enum' => %w[a b c],
            'type' => 'string'
          }
        },
        'required' => ['letter'],
        'type' => 'object'
      )
    end
  end

  context 'Array in proc values' do
    subject(:array_in_proc) { first_parameter_info('array_in_proc') }

    it 'has proc returned values as array in enum' do
      expect(array_in_proc).to eq(
        'properties' => {
          'letter' => {
            'enum' => %w[d e f],
            'type' => 'string'
          }
        }, 'required' => ['letter'],
        'type' => 'object'
      )
    end
  end

  context 'Range values' do
    subject(:range_letter) { first_parameter_info('range_letter') }

    it 'has letter range values' do
      expect(range_letter).to eq(
        'properties' => {
          'letter' => { 'enum' => %w[a b c d e f g h i j k l m n o p q r s t u v w x y z], 'type' => 'string' }
        },
        'required' => ['letter'],
        'type' => 'object'
      )
    end

    subject(:range_integer) { first_parameter_info('range_integer') }

    it 'has integer range values' do
      expect(range_integer).to eq(
        'properties' => {
          'integer' => {
            'format' => 'int32',
            'maximum' => 5,
            'minimum' => -5,
            'type' => 'integer'
          }
        },
        'required' => ['integer'],
        'type' => 'object'
      )
    end
  end
end

describe 'Convert values to enum for float range and not arrays inside a proc', if: GrapeVersion.satisfy?('>= 0.11.0') do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :letter, type: String, values: proc { 'string' }
      end
      post :non_array_in_proc do
      end

      params do
        requires :float, type: Float, values: -5.0..5.0
      end
      post :range_float do
      end

      add_swagger_documentation openapi_version: '3.0'
    end
  end

  def first_parameter_info(request)
    get "/swagger_doc/#{request}"
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    body['paths']["/#{request}"]['post']['requestBody']['content']['application/x-www-form-urlencoded']['schema']
  end

  context 'Non array in proc values' do
    subject(:non_array_in_proc) { first_parameter_info('non_array_in_proc') }

    it 'has proc returned value as string in enum' do
      expect(non_array_in_proc).to eq(
        'properties' => {
          'letter' => {
            'enum' => ['string'],
            'type' => 'string'
          }
        },
        'required' => ['letter'],
        'type' => 'object'
      )
    end
  end

  context 'Range values' do
    subject(:range_float) { first_parameter_info('range_float') }

    it 'has float range values as string' do
      expect(range_float).to eq(
        'properties' => {
          'float' => {
            'format' => 'float', 'maximum' => 5.0, 'minimum' => -5.0, 'type' => 'number'
          }
        },
        'required' => ['float'],
        'type' => 'object'
      )
    end
  end
end
