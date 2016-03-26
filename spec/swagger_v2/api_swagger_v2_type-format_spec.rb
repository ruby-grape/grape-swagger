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
          expose :prop_integer,   documentation: { type: Integer, desc: 'prop_integer' }
          expose :prop_long,      documentation: { type: Numeric, desc: 'prop_long' }
          expose :prop_float,     documentation: { type: Float, desc: 'prop_float' }
          expose :prop_double,    documentation: { type: BigDecimal, desc: 'prop_double' }
          expose :prop_string,    documentation: { type: String, desc: 'prop_string' }
          expose :prop_symbol,    documentation: { type: Symbol, desc: 'prop_symbol' }
          expose :prop_date,      documentation: { type: Date, desc: 'prop_date' }
          expose :prop_date_time, documentation: { type: DateTime, desc: 'prop_date_time' }
          expose :prop_time,      documentation: { type: Time, desc: 'prop_time' }
          expose :prop_password,  documentation: { type: 'password', desc: 'prop_password' }
          expose :prop_email,     documentation: { type: 'email', desc: 'prop_email' }
          expose :prop_boolean,   documentation: { type: Virtus::Attribute::Boolean, desc: 'prop_boolean' }
          expose :prop_file,      documentation: { type: File, desc: 'prop_file' }
          expose :prop_json,      documentation: { type: JSON, desc: 'prop_json' }
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
      {"in"=>"formData", "name"=>"param_integer", "description"=>nil, "required"=>true, "type"=>"integer", "format"=>"int32"},
      {"in"=>"formData", "name"=>"param_long", "description"=>nil, "required"=>true, "type"=>"integer", "format"=>"int64"},
      {"in"=>"formData", "name"=>"param_float", "description"=>nil, "required"=>true, "type"=>"number", "format"=>"float"},
      {"in"=>"formData", "name"=>"param_double", "description"=>nil, "required"=>true, "type"=>"number", "format"=>"double"},
      {"in"=>"formData", "name"=>"param_string", "description"=>nil, "required"=>false, "type"=>"string"},
      {"in"=>"formData", "name"=>"param_symbol", "description"=>nil, "required"=>false, "type"=>"string"},
      {"in"=>"formData", "name"=>"param_date", "description"=>nil, "required"=>true, "type"=>"string", "format"=>"date"},
      {"in"=>"formData", "name"=>"param_date_time", "description"=>nil, "required"=>true, "type"=>"string", "format"=>"date-time"},
      {"in"=>"formData", "name"=>"param_time", "description"=>nil, "required"=>true, "type"=>"string", "format"=>"date-time"},
      {"in"=>"formData", "name"=>"param_password", "description"=>nil, "required"=>true, "type"=>"string", "format"=>"password"},
      {"in"=>"formData", "name"=>"param_email", "description"=>nil, "required"=>true, "type"=>"string", "format"=>"email"},
      {"in"=>"formData", "name"=>"param_boolean", "description"=>nil, "required"=>false, "type"=>"boolean"},
      {"in"=>"formData", "name"=>"param_file", "description"=>nil, "required"=>false, "type"=>"file"},
      {"in"=>"formData", "name"=>"param_json", "description"=>nil, "required"=>false, "type"=>"json"}
    ])
  end

  specify do
    expect(subject['definitions']['TypedDefinition']['properties']).to eql({
      "prop_integer"=>{"type"=>"integer", "format"=>"int32"},
      "prop_long"=>{"type"=>"integer", "format"=>"int64"},
      "prop_float"=>{"type"=>"number", "format"=>"float"},
      "prop_double"=>{"type"=>"number", "format"=>"double"},
      "prop_string"=>{"type"=>"string"},
      "prop_symbol"=>{"type"=>"string"},
      "prop_date"=>{"type"=>"string", "format"=>"date"},
      "prop_date_time"=>{"type"=>"string", "format"=>"date-time"},
      "prop_time"=>{"type"=>"string", "format"=>"date-time"},
      "prop_password"=>{"type"=>"string", "format"=>"password"},
      "prop_email"=>{"type"=>"string", "format"=>"email"},
      "prop_boolean"=>{"type"=>"boolean"},
      "prop_file"=>{"type"=>"file"},
      "prop_json"=>{"type"=>"json"}
    })
  end
end
