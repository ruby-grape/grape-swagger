require 'spec_helper'

describe 'response' do
  include_context "the api entities"

  before :all do
    module TheApi
      class ResponseApi < Grape::API
        format :json

        desc 'This returns something',
          params: Entities::UseResponse.documentation,
          failure: [{code: 400, message: 'NotFound', model: Entities::ApiError}]
        post '/params_response' do
          { "declared_params" => declared(params) }
        end

        desc 'This returns something',
          entity: Entities::UseResponse,
          failure: [{code: 400, message: 'NotFound', model: Entities::ApiError}]
        get '/entity_response' do
          { "declared_params" => declared(params) }
        end

        desc 'This returns something',
          entity: Entities::UseItemResponseAsType,
          failure: [{code: 400, message: 'NotFound', model: Entities::ApiError}]
        get '/nested_type' do
          { "declared_params" => declared(params) }
        end


        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::ResponseApi
  end

  describe "uses nested type as response object" do
    subject do
      get '/swagger_doc/nested_type'
      JSON.parse(last_response.body)
    end
    specify do
      expect(subject['paths']['/nested_type']['get']).to eql({
        'description'=>'This returns something',
        'produces'=>['application/json'],
        'responses'=>{
          '200'=>{'description'=>'This returns something', 'schema'=>{'$ref'=>'#/definitions/UseItemResponseAsType'}},
          '400'=>{'description'=>'NotFound', 'schema'=>{'$ref'=>'#/definitions/ApiError'}}
        },
        'tags'=>['nested_type'],
        'operationId'=>'getNestedType'
      })
      expect(subject['definitions']).to eql({
        'ResponseItem'=>{
          'type'=>'object',
          'properties'=>{
            'id'=>{'type'=>'integer', 'format'=>'int32'},
            'name'=>{'type'=>'string'}
          }
        },
        'UseItemResponseAsType'=>{
          'type'=>'object',
          'properties'=>{
            'description'=>{'type'=>'string'},
            'responses'=>{'$ref'=>'#/definitions/ResponseItem'}
          },
          'description'=>'This returns something'
        },
        'ApiError'=>{
          'type'=>'object',
          'properties'=>{
            'code'=>{'type'=>'integer', 'format'=>'int32'},
            'message'=>{'type'=>'string'}},
            'description'=>'This returns something'
      }})
    end
  end

  describe "uses entity as response object" do
    subject do
      get '/swagger_doc/entity_response'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/entity_response']['get']).to eql({
        'description'=>'This returns something',
        'produces'=>['application/json'],
        'responses'=>{
          '200'=>{'description'=>'This returns something', 'schema'=>{'$ref'=>'#/definitions/UseResponse'}},
          '400'=>{'description'=>'NotFound', 'schema'=>{'$ref'=>'#/definitions/ApiError'}}
        },
        'tags'=>['entity_response'],
        'operationId'=>'getEntityResponse'
      })
      expect(subject['definitions']).to eql({
        'ResponseItem'=>{
          'type'=>'object',
          'properties'=>{
            'id'=>{'type'=>'integer', 'format'=>'int32'},
            'name'=>{'type'=>'string'}
          }
        },
        'UseResponse'=>{
          'type'=>'object',
          'properties'=>{
            'description'=>{'type'=>'string'},
            '$responses'=>{'type'=>'array', 'items'=>{'$ref'=>'#/definitions/ResponseItem'}}
          },
          'description'=>'This returns something'
        },
        'ApiError'=>{
          'type'=>'object',
          'properties'=>{'code'=>{'type'=>'integer', 'format'=>'int32'}, 'message'=>{'type'=>'string'}},
          'description'=>'This returns something'
      }})
    end
  end

  describe "uses params as response object" do
    subject do
      get '/swagger_doc/params_response'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/params_response']['post']).to eql({
        'description'=>'This returns something',
        'produces'=>['application/json'],
        'consumes'=>['application/json'],
        'parameters'=>[
          {'in'=>'formData', 'name'=>'description', 'type'=>'string', 'required'=>false},
          {'in'=>'formData', 'name'=>'$responses', 'type'=>'array', 'items'=>{'type'=>'string'}, 'required'=>false}
        ],
        'responses'=>{
          '201'=>{'description'=>'This returns something'},
          '400'=>{'description'=>'NotFound', 'schema'=>{'$ref'=>'#/definitions/ApiError'}}
        },
        'tags'=>['params_response'],
        'operationId'=>'postParamsResponse'
      })
      expect(subject['definitions']).to eql({
        'ApiError'=>{
          'type'=>'object',
          'properties'=>{'code'=>{'type'=>'integer', 'format'=>'int32'}, 'message'=>{'type'=>'string'}},
          'description'=>'This returns something'
      }})
    end
  end
end
