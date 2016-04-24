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
  before :all do
    module TheApi
      module Entities
        class TypedDefinition < Grape::Entity
          expose :prop_integer,   documentation: { type: Integer, desc: 'prop_integer description' }
          expose :prop_long,      documentation: { type: Numeric, desc: 'prop_long description' }
          expose :prop_float,     documentation: { type: Float, desc: 'prop_float description' }
          expose :prop_double,    documentation: { type: BigDecimal, desc: 'prop_double description' }
          expose :prop_string,    documentation: { type: String, desc: 'prop_string description' }
          expose :prop_symbol,    documentation: { type: Symbol, desc: 'prop_symbol description' }
          expose :prop_date,      documentation: { type: Date, desc: 'prop_date description' }
          expose :prop_date_time, documentation: { type: DateTime, desc: 'prop_date_time description' }
          expose :prop_time,      documentation: { type: Time, desc: 'prop_time description' }
          expose :prop_password,  documentation: { type: 'password', desc: 'prop_password description' }
          expose :prop_email,     documentation: { type: 'email', desc: 'prop_email description' }
          expose :prop_boolean,   documentation: { type: Virtus::Attribute::Boolean, desc: 'prop_boolean description' }
          expose :prop_file,      documentation: { type: File, desc: 'prop_file description' }
          expose :prop_json,      documentation: { type: JSON, desc: 'prop_json description' }
        end
      end

      class TypeFormatApi < Grape::API
        desc 'full set of request data types',
          success: TheApi::Entities::TypedDefinition

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
          requires :param_password,  type: 'password'
          requires :param_email,     type: 'email'
          optional :param_boolean,   type: Boolean
          optional :param_file,      type: File
          optional :param_json,      type: JSON
        end

        post '/request_types' do
          { "declared_params" => declared(params) }
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
    expect(subject['paths']['/request_types']['post']['parameters']).to eql([
      {"in"=>"formData", "name"=>"param_integer", "required"=>true, "type"=>"integer", "format"=>"int32"},
      {"in"=>"formData", "name"=>"param_long", "required"=>true, "type"=>"integer", "format"=>"int64"},
      {"in"=>"formData", "name"=>"param_float", "required"=>true, "type"=>"number", "format"=>"float"},
      {"in"=>"formData", "name"=>"param_double", "required"=>true, "type"=>"number", "format"=>"double"},
      {"in"=>"formData", "name"=>"param_string", "required"=>false, "type"=>"string"},
      {"in"=>"formData", "name"=>"param_symbol", "required"=>false, "type"=>"string"},
      {"in"=>"formData", "name"=>"param_date", "required"=>true, "type"=>"string", "format"=>"date"},
      {"in"=>"formData", "name"=>"param_date_time", "required"=>true, "type"=>"string", "format"=>"date-time"},
      {"in"=>"formData", "name"=>"param_time", "required"=>true, "type"=>"string", "format"=>"date-time"},
      {"in"=>"formData", "name"=>"param_password", "required"=>true, "type"=>"string", "format"=>"password"},
      {"in"=>"formData", "name"=>"param_email", "required"=>true, "type"=>"string", "format"=>"email"},
      {"in"=>"formData", "name"=>"param_boolean", "required"=>false, "type"=>"boolean"},
      {"in"=>"formData", "name"=>"param_file", "required"=>false, "type"=>"file"},
      {"in"=>"formData", "name"=>"param_json", "required"=>false, "type"=>"json"}
    ])
  end

  specify do
    expect(subject['definitions']['TypedDefinition']['properties']).to eql({
      "prop_integer"=>{"type"=>"integer", "format"=>"int32", "description"=>"prop_integer description"},
      "prop_long"=>{"type"=>"integer", "format"=>"int64", "description"=>"prop_long description"},
      "prop_float"=>{"type"=>"number", "format"=>"float", "description"=>"prop_float description"},
      "prop_double"=>{"type"=>"number", "format"=>"double", "description"=>"prop_double description"},
      "prop_string"=>{"type"=>"string", "description"=>"prop_string description"},
      "prop_symbol"=>{"type"=>"string", "description"=>"prop_symbol description"},
      "prop_date"=>{"type"=>"string", "format"=>"date", "description"=>"prop_date description"},
      "prop_date_time"=>{"type"=>"string", "format"=>"date-time", "description"=>"prop_date_time description"},
      "prop_time"=>{"type"=>"string", "format"=>"date-time", "description"=>"prop_time description"},
      "prop_password"=>{"type"=>"string", "format"=>"password", "description"=>"prop_password description"},
      "prop_email"=>{"type"=>"string", "format"=>"email", "description"=>"prop_email description"},
      "prop_boolean"=>{"type"=>"boolean", "description"=>"prop_boolean description"},
      "prop_file"=>{"type"=>"file", "description"=>"prop_file description"},
      "prop_json"=>{"type"=>"json", "description"=>"prop_json description"}
    })
  end
end
