# frozen_string_literal: true

require 'spec_helper'

# mapping of parameter types
# Grape                         ->  Swagger (OpenApi)
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
# JSON                          ->  json
# Rack::Multipart::UploadedFile ->  file

describe 'type format settings' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
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
    TheApi::TypeFormatApi
  end

  subject do
    get '/swagger_doc/request_types'
    JSON.parse(last_response.body)
  end

  specify do
    expect(subject['paths']['/request_types']['post']['requestBody']).to eql(
      'content' => {
        'application/json' => {
          'schema' => {
            'properties' => {
              'param_json' => { 'type' => 'object' }
            },
            'type' => 'object'
          }
        },
        'application/octet-stream' => {
          'schema' => {
            'properties' => {
              'param_file' => {
                'format' => 'binary', 'type' => 'string'
              }
            },
            'type' => 'object'
          }
        },
        'application/x-www-form-urlencoded' => {
          'schema' => {
            'properties' => {
              'param_boolean' => { 'type' => 'boolean' },
              'param_date' => { 'format' => 'date', 'type' => 'string' },
              'param_date_time' => { 'format' => 'date-time', 'type' => 'string' },
              'param_double' => { 'format' => 'double', 'type' => 'number' },
              'param_float' => { 'format' => 'float', 'type' => 'number' },
              'param_integer' => { 'format' => 'int32', 'type' => 'integer' },
              'param_long' => { 'format' => 'int64', 'type' => 'integer' },
              'param_string' => { 'type' => 'string' },
              'param_symbol' => { 'type' => 'string' },
              'param_time' => { 'format' => 'date-time', 'type' => 'string' }
            },
            'required' => %w[param_integer param_long param_float param_double param_date param_date_time param_time],
            'type' => 'object'
          }
        }
      }
    )
  end

  specify do
    expect(subject['components']['schemas']['TypedDefinition']['properties']).to eql(swagger_typed_defintion)
  end
end
