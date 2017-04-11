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

        add_swagger_documentation
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
    expect(subject['paths']['/request_types']['post']['parameters']).to eql(
      [
        { 'in' => 'formData', 'name' => 'param_integer', 'required' => true, 'type' => 'integer', 'format' => 'int32' },
        { 'in' => 'formData', 'name' => 'param_long', 'required' => true, 'type' => 'integer', 'format' => 'int64' },
        { 'in' => 'formData', 'name' => 'param_float', 'required' => true, 'type' => 'number', 'format' => 'float' },
        { 'in' => 'formData', 'name' => 'param_double', 'required' => true, 'type' => 'number', 'format' => 'double' },
        { 'in' => 'formData', 'name' => 'param_string', 'required' => false, 'type' => 'string' },
        { 'in' => 'formData', 'name' => 'param_symbol', 'required' => false, 'type' => 'string' },
        { 'in' => 'formData', 'name' => 'param_date', 'required' => true, 'type' => 'string', 'format' => 'date' },
        { 'in' => 'formData', 'name' => 'param_date_time', 'required' => true, 'type' => 'string', 'format' => 'date-time' },
        { 'in' => 'formData', 'name' => 'param_time', 'required' => true, 'type' => 'string', 'format' => 'date-time' },
        { 'in' => 'formData', 'name' => 'param_boolean', 'required' => false, 'type' => 'boolean' },
        { 'in' => 'formData', 'name' => 'param_file', 'required' => false, 'type' => 'file' },
        { 'in' => 'formData', 'name' => 'param_json', 'required' => false, 'type' => 'json' }
      ]
    )
  end

  specify do
    expect(subject['definitions']['TypedDefinition']['properties']).to eql(swagger_typed_defintion)
  end
end
