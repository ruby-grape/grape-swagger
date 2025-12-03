# frozen_string_literal: true

require 'spec_helper'

# mapping of parameter types
# Grape                         ->  OpenAPI 3.0
#                                   (type format)
# ---------------------------------------------------
# Integer                       ->  integer int32
# Numeric                       ->  integer int64
# Float                         ->  number float
# BigDecimal                    ->  number double
# String                        ->  string
# Symbol                        ->  string
# Date                          ->  string date
# DateTime                      ->  string date-time
# Time                          ->  string date-time
# 'password'                    ->  string password
# 'email'                       ->  string email
# Boolean                       ->  boolean
# JSON                          ->  object
# Rack::Multipart::UploadedFile ->  string binary
# File                          ->  string binary

describe 'OAS 3.0 type format settings' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApiOAS3
      class TypeFormatApi < Grape::API
        desc 'full set of request data types',
             success: Entities::TypedDefinition

        params do
          # grape supported data types
          requires :param_integer,   type: Integer
          requires :param_long,      type: Numeric
          requires :param_float,     type: Float
          requires :param_double,    type: BigDecimal
          optional :param_string,    type: String
          optional :param_symbol,    type: Symbol
          requires :param_date,      type: Date
          requires :param_date_time, type: DateTime
          requires :param_time,      type: Time
          optional :param_boolean,   type: Boolean
          optional :param_file,      type: File
          optional :param_json,      type: JSON
        end

        post '/request_types' do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation openapi_version: '3.0'
      end
    end
  end

  def app
    TheApiOAS3::TypeFormatApi
  end

  subject do
    get '/swagger_doc/request_types'
    JSON.parse(last_response.body)
  end

  describe 'requestBody schema' do
    let(:request_body) { subject['paths']['/request_types']['post']['requestBody'] }
    let(:schemas) { subject['components']['schemas'] }
    let(:body_schema) { schemas['postRequestTypes'] }

    it 'has requestBody with content' do
      expect(request_body).to be_present
      expect(request_body['content']).to be_present
    end

    it 'references component schema' do
      expect(request_body['content']['application/json']['schema']['$ref']).to eq('#/components/schemas/postRequestTypes')
    end

    describe 'integer types' do
      it 'maps Integer to integer/int32' do
        prop = body_schema['properties']['param_integer']
        expect(prop['type']).to eq('integer')
        expect(prop['format']).to eq('int32')
      end

      it 'maps Numeric to integer/int64' do
        prop = body_schema['properties']['param_long']
        expect(prop['type']).to eq('integer')
        expect(prop['format']).to eq('int64')
      end
    end

    describe 'number types' do
      it 'maps Float to number/float' do
        prop = body_schema['properties']['param_float']
        expect(prop['type']).to eq('number')
        expect(prop['format']).to eq('float')
      end

      it 'maps BigDecimal to number/double' do
        prop = body_schema['properties']['param_double']
        expect(prop['type']).to eq('number')
        expect(prop['format']).to eq('double')
      end
    end

    describe 'string types' do
      it 'maps String to string' do
        prop = body_schema['properties']['param_string']
        expect(prop['type']).to eq('string')
      end

      it 'maps Symbol to string' do
        prop = body_schema['properties']['param_symbol']
        expect(prop['type']).to eq('string')
      end
    end

    describe 'date/time types' do
      it 'maps Date to string/date' do
        prop = body_schema['properties']['param_date']
        expect(prop['type']).to eq('string')
        expect(prop['format']).to eq('date')
      end

      it 'maps DateTime to string/date-time' do
        prop = body_schema['properties']['param_date_time']
        expect(prop['type']).to eq('string')
        expect(prop['format']).to eq('date-time')
      end

      it 'maps Time to string/date-time' do
        prop = body_schema['properties']['param_time']
        expect(prop['type']).to eq('string')
        expect(prop['format']).to eq('date-time')
      end
    end

    describe 'boolean type' do
      it 'maps Boolean to boolean' do
        prop = body_schema['properties']['param_boolean']
        expect(prop['type']).to eq('boolean')
      end
    end

    describe 'file type' do
      it 'maps File to string/binary' do
        prop = body_schema['properties']['param_file']
        expect(prop['type']).to eq('string')
        expect(prop['format']).to eq('binary')
      end
    end

    describe 'json type' do
      it 'maps JSON to object' do
        prop = body_schema['properties']['param_json']
        expect(prop['type']).to eq('object')
      end
    end

    describe 'required fields' do
      it 'marks required parameters' do
        required = body_schema['required']
        expect(required).to include('param_integer')
        expect(required).to include('param_long')
        expect(required).to include('param_float')
        expect(required).to include('param_double')
        expect(required).to include('param_date')
        expect(required).to include('param_date_time')
        expect(required).to include('param_time')
      end

      it 'does not include optional parameters in required' do
        required = body_schema['required']
        expect(required).not_to include('param_string')
        expect(required).not_to include('param_symbol')
        expect(required).not_to include('param_boolean')
        expect(required).not_to include('param_file')
        expect(required).not_to include('param_json')
      end
    end
  end

  describe 'response schema' do
    it 'includes TypedDefinition in components schemas' do
      expect(subject['components']['schemas']['TypedDefinition']).to be_present
    end

    it 'has expected properties for TypedDefinition' do
      typed_def = subject['components']['schemas']['TypedDefinition']
      expect(typed_def['properties']).to eq(swagger_typed_definition)
    end
  end
end
