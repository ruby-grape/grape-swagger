# frozen_string_literal: true

RSpec.shared_context 'entity swagger example' do
  before :all do
    module Entities
      class Something < Grape::Entity
        expose :id, documentation: { type: Integer, desc: 'Identity of Something' }
        expose :text, documentation: { type: String, desc: 'Content of something.' }
        expose :links, documentation: { type: 'link', is_array: true }
        expose :others, documentation: { type: 'text', is_array: false }
      end

      class EnumValues < Grape::Entity
        expose :gender, documentation: { type: 'string', desc: 'Content of something.', values: %w[Male Female] }
        expose :number, documentation: { type: 'integer', desc: 'Content of something.', values: [1, 2] }
      end

      class AliasedThing < Grape::Entity
        expose :something, as: :post, using: Entities::Something, documentation: { type: 'Something', desc: 'Reference to something.' }
      end

      class FourthLevel < Grape::Entity
        expose :text, documentation: { type: 'string' }
      end

      class ThirdLevel < Grape::Entity
        expose :parts, using: Entities::FourthLevel, documentation: { type: 'FourthLevel' }
      end

      class SecondLevel < Grape::Entity
        expose :parts, using: Entities::ThirdLevel, documentation: { type: 'ThirdLevel' }
      end

      class FirstLevel < Grape::Entity
        expose :parts, using: Entities::SecondLevel, documentation: { type: 'SecondLevel' }
      end

      class QueryInputElement < Grape::Entity
        expose :key, documentation: {
          type: String, desc: 'Name of parameter', required: true
        }
        expose :value, documentation: {
          type: String, desc: 'Value of parameter', required: true
        }
      end

      class QueryInput < Grape::Entity
        expose :elements, using: Entities::QueryInputElement, documentation: {
          type: 'QueryInputElement',
          desc: 'Set of configuration',
          param_type: 'body',
          is_array: true,
          required: true
        }
      end

      class ApiError < Grape::Entity
        expose :code, documentation: { type: Integer, desc: 'status code' }
        expose :message, documentation: { type: String, desc: 'error message' }
      end

      module NestedModule
        class ApiResponse < Grape::Entity
          expose :status, documentation: { type: String }
          expose :error, documentation: { type: ::Entities::ApiError }
        end
      end

      class SecondApiError < Grape::Entity
        expose :code, documentation: { type: Integer }
        expose :severity, documentation: { type: String }
        expose :message, documentation: { type: String }
      end

      class ResponseItem < Grape::Entity
        expose :id, documentation: { type: Integer }
        expose :name, documentation: { type: String }
      end

      class OtherItem < Grape::Entity
        expose :key, documentation: { type: Integer }
        expose :symbol, documentation: { type: String }
      end

      class UseResponse < Grape::Entity
        expose :description, documentation: { type: String }
        expose :items, as: '$responses', using: Entities::ResponseItem, documentation: { is_array: true }
      end

      class UseItemResponseAsType < Grape::Entity
        expose :description, documentation: { type: String }
        expose :responses, documentation: { type: Entities::ResponseItem, is_array: false }
      end

      class UseAddress < Grape::Entity
        expose :street, documentation: { type: String, desc: 'street' }
        expose :postcode, documentation: { type: String, desc: 'postcode' }
        expose :city, documentation: { type: String, desc: 'city' }
        expose :country, documentation: { type: String, desc: 'country' }
      end

      class UseNestedWithAddress < Grape::Entity
        expose :name, documentation: { type: String }
        expose :address, using: Entities::UseAddress
      end

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
        expose :prop_boolean,   documentation: { type: Grape::API::Boolean, desc: 'prop_boolean description' }
        expose :prop_file,      documentation: { type: File, desc: 'prop_file description' }
        expose :prop_json,      documentation: { type: JSON, desc: 'prop_json description' }
      end

      class RecursiveModel < Grape::Entity
        expose :name, documentation: { type: String, desc: 'The name.' }
        expose :children, using: self, documentation: { type: 'RecursiveModel', is_array: true, desc: 'The child nodes.' }
      end

      class DocumentedHashAndArrayModel < Grape::Entity
        expose :raw_hash, documentation: { type: Hash, desc: 'Example Hash.', documentation: { in: 'body' } }
        expose :raw_array, documentation: { type: Array, desc: 'Example Array', documentation: { in: 'body' } }
      end
    end
  end

  let(:swagger_definitions_models) do
    {
      'ApiError' => { 'type' => 'object', 'properties' => { 'code' => { 'type' => 'integer', 'format' => 'int32', 'description' => 'status code' }, 'message' => { 'type' => 'string', 'description' => 'error message' } } },
      'ResponseItem' => { 'type' => 'object', 'properties' => { 'id' => { 'type' => 'integer', 'format' => 'int32' }, 'name' => { 'type' => 'string' } } },
      'UseResponse' => { 'type' => 'object', 'properties' => { 'description' => { 'type' => 'string' }, '$responses' => { 'type' => 'array', 'items' => { '$ref' => '#/definitions/ResponseItem' } } } },
      'RecursiveModel' => { 'type' => 'object', 'properties' => { 'name' => { 'type' => 'string', 'description' => 'The name.' }, 'children' => { 'type' => 'array', 'items' => { '$ref' => '#/definitions/RecursiveModel' }, 'description' => 'The child nodes.' } } },
      'DocumentedHashAndArrayModel' => { 'type' => 'object', 'properties' => { 'raw_hash' => { 'type' => 'object', 'description' => 'Example Hash.' }, 'raw_array' => { 'type' => 'array', 'description' => 'Example Array' } } }
    }
  end

  let(:swagger_nested_type) do
    {
      'ApiError' => { 'type' => 'object', 'properties' => { 'code' => { 'type' => 'integer', 'format' => 'int32', 'description' => 'status code' }, 'message' => { 'type' => 'string', 'description' => 'error message' } }, 'description' => 'ApiError model' },
      'ResponseItem' => { 'type' => 'object', 'properties' => { 'id' => { 'type' => 'integer', 'format' => 'int32' }, 'name' => { 'type' => 'string' } } },
      'UseItemResponseAsType' => { 'type' => 'object', 'properties' => { 'description' => { 'type' => 'string' }, 'responses' => { '$ref' => '#/definitions/ResponseItem' } }, 'description' => 'UseItemResponseAsType model' }
    }
  end

  let(:swagger_entity_as_response_object) do
    {
      'ApiError' => { 'type' => 'object', 'properties' => { 'code' => { 'type' => 'integer', 'format' => 'int32', 'description' => 'status code' }, 'message' => { 'type' => 'string', 'description' => 'error message' } }, 'description' => 'ApiError model' },
      'ResponseItem' => { 'type' => 'object', 'properties' => { 'id' => { 'type' => 'integer', 'format' => 'int32' }, 'name' => { 'type' => 'string' } } },
      'UseResponse' => { 'type' => 'object', 'properties' => { 'description' => { 'type' => 'string' }, '$responses' => { 'type' => 'array', 'items' => { '$ref' => '#/definitions/ResponseItem' } } }, 'description' => 'UseResponse model' }
    }
  end

  let(:swagger_params_as_response_object) do
    {
      'ApiError' => { 'type' => 'object', 'properties' => { 'code' => { 'description' => 'status code', 'type' => 'integer', 'format' => 'int32' }, 'message' => { 'description' => 'error message', 'type' => 'string' } }, 'description' => 'ApiError model' }
    }
  end

  let(:swagger_typed_defintion) do
    {
      'prop_boolean' => { 'description' => 'prop_boolean description', 'type' => 'boolean' },
      'prop_date' => { 'description' => 'prop_date description', 'type' => 'string', 'format' => 'date' },
      'prop_date_time' => { 'description' => 'prop_date_time description', 'type' => 'string', 'format' => 'date-time' },
      'prop_double' => { 'description' => 'prop_double description', 'type' => 'number', 'format' => 'double' },
      'prop_email' => { 'description' => 'prop_email description', 'type' => 'string', 'format' => 'email' },
      'prop_file' => { 'description' => 'prop_file description', 'type' => 'file' },
      'prop_float' => { 'description' => 'prop_float description', 'type' => 'number', 'format' => 'float' },
      'prop_integer' => { 'description' => 'prop_integer description', 'type' => 'integer', 'format' => 'int32' },
      'prop_json' => { 'description' => 'prop_json description', 'type' => 'json' },
      'prop_long' => { 'description' => 'prop_long description', 'type' => 'integer', 'format' => 'int64' },
      'prop_password' => { 'description' => 'prop_password description', 'type' => 'string', 'format' => 'password' },
      'prop_string' => { 'description' => 'prop_string description', 'type' => 'string' },
      'prop_symbol' => { 'description' => 'prop_symbol description', 'type' => 'string' },
      'prop_time' => { 'description' => 'prop_time description', 'type' => 'string', 'format' => 'date-time' }
    }
  end

  let(:swagger_json) do
    {
      'info' => {
        'title' => 'The API title to be displayed on the API homepage.',
        'description' => 'A description of the API.',
        'termsOfService' => 'www.The-URL-of-the-terms-and-service.com',
        'contact' => { 'name' => 'Contact name', 'email' => 'Contact@email.com', 'url' => 'Contact URL' },
        'license' => { 'name' => 'The name of the license.', 'url' => 'www.The-URL-of-the-license.org' },
        'version' => '0.0.1'
      },
      'swagger' => '2.0',
      'produces' => ['application/json'],
      'host' => 'example.org',
      'basePath' => '/api',
      'tags' => [
        { 'name' => 'other_thing', 'description' => 'Operations about other_things' },
        { 'name' => 'thing', 'description' => 'Operations about things' },
        { 'name' => 'thing2', 'description' => 'Operations about thing2s' },
        { 'name' => 'dummy', 'description' => 'Operations about dummies' }
      ],
      'paths' => {
        '/v3/other_thing/{elements}' => {
          'get' => {
            'description' => 'nested route inside namespace',
            'produces' => ['application/json'],
            'parameters' => [{ 'in' => 'body', 'name' => 'elements', 'description' => 'Set of configuration', 'type' => 'array', 'items' => { 'type' => 'string' }, 'required' => true }],
            'responses' => { '200' => { 'description' => 'nested route inside namespace', 'schema' => { '$ref' => '#/definitions/QueryInput' } } },
            'tags' => ['other_thing'],
            'operationId' => 'getV3OtherThingElements',
            'x-amazon-apigateway-auth' => { 'type' => 'none' },
            'x-amazon-apigateway-integration' => { 'type' => 'aws', 'uri' => 'foo_bar_uri', 'httpMethod' => 'get' }
          }
        },
        '/thing' => {
          'get' => {
            'description' => 'This gets Things.',
            'produces' => ['application/json'],
            'parameters' => [
              { 'in' => 'query', 'name' => 'id', 'description' => 'Identity of Something', 'type' => 'integer', 'format' => 'int32', 'required' => false },
              { 'in' => 'query', 'name' => 'text', 'description' => 'Content of something.', 'type' => 'string', 'required' => false },
              { 'in' => 'formData', 'name' => 'links', 'type' => 'array', 'items' => { 'type' => 'link' }, 'required' => false },
              { 'in' => 'query', 'name' => 'others', 'type' => 'text', 'required' => false }
            ],
            'responses' => { '200' => { 'description' => 'This gets Things.' }, '401' => { 'description' => 'Unauthorized', 'schema' => { '$ref' => '#/definitions/ApiError' } } },
            'tags' => ['thing'],
            'operationId' => 'getThing'
          },
          'post' => {
            'description' => 'This creates Thing.',
            'produces' => ['application/json'],
            'consumes' => ['application/json'],
            'parameters' => [
              { 'in' => 'formData', 'name' => 'text', 'description' => 'Content of something.', 'type' => 'string', 'required' => true },
              { 'in' => 'formData', 'name' => 'links', 'type' => 'array', 'items' => { 'type' => 'string' }, 'required' => true }
            ],
            'responses' => { '201' => { 'description' => 'This creates Thing.', 'schema' => { '$ref' => '#/definitions/Something' } }, '422' => { 'description' => 'Unprocessible Entity' } },
            'tags' => ['thing'],
            'operationId' => 'postThing'
          }
        },
        '/thing/{id}' => {
          'get' => {
            'description' => 'This gets Thing.',
            'produces' => ['application/json'],
            'parameters' => [{ 'in' => 'path', 'name' => 'id', 'type' => 'integer', 'format' => 'int32', 'required' => true }],
            'responses' => { '200' => { 'description' => 'getting a single thing' }, '401' => { 'description' => 'Unauthorized' } },
            'tags' => ['thing'],
            'operationId' => 'getThingId'
          },
          'put' => {
            'description' => 'This updates Thing.',
            'produces' => ['application/json'],
            'consumes' => ['application/json'],
            'parameters' => [
              { 'in' => 'path', 'name' => 'id', 'type' => 'integer', 'format' => 'int32', 'required' => true },
              { 'in' => 'formData', 'name' => 'text', 'description' => 'Content of something.', 'type' => 'string', 'required' => false },
              { 'in' => 'formData', 'name' => 'links', 'type' => 'array', 'items' => { 'type' => 'string' }, 'required' => false }
            ],
            'responses' => { '200' => { 'description' => 'This updates Thing.', 'schema' => { '$ref' => '#/definitions/Something' } } },
            'tags' => ['thing'],
            'operationId' => 'putThingId'
          },
          'delete' => {
            'description' => 'This deletes Thing.',
            'produces' => ['application/json'],
            'parameters' => [{ 'in' => 'path', 'name' => 'id', 'type' => 'integer', 'format' => 'int32', 'required' => true }],
            'responses' => { '200' => { 'description' => 'This deletes Thing.', 'schema' => { '$ref' => '#/definitions/Something' } } },
            'tags' => ['thing'],
            'operationId' => 'deleteThingId'
          }
        },
        '/thing2' => {
          'get' => {
            'description' => 'This gets Things.',
            'produces' => ['application/json'],
            'responses' => { '200' => { 'description' => 'get Horses', 'schema' => { '$ref' => '#/definitions/Something' } }, '401' => { 'description' => 'HorsesOutError', 'schema' => { '$ref' => '#/definitions/ApiError' } } },
            'tags' => ['thing2'],
            'operationId' => 'getThing2'
          }
        },
        '/dummy/{id}' => {
          'delete' => {
            'description' => 'dummy route.',
            'produces' => ['application/json'],
            'parameters' => [{ 'in' => 'path', 'name' => 'id', 'type' => 'integer', 'format' => 'int32', 'required' => true }],
            'responses' => { '204' => { 'description' => 'dummy route.' }, '401' => { 'description' => 'Unauthorized' } },
            'tags' => ['dummy'],
            'operationId' => 'deleteDummyId'
          }
        }
      },
      'definitions' => {
        'QueryInput' => {
          'type' => 'object',
          'required' => ['elements'],
          'properties' => { 'elements' => { 'type' => 'array', 'items' => { '$ref' => '#/definitions/QueryInputElement' }, 'description' => 'Set of configuration' } },
          'description' => 'QueryInput model'
        },
        'QueryInputElement' => {
          'type' => 'object',
          'required' => %w[key value],
          'properties' => { 'key' => { 'type' => 'string', 'description' => 'Name of parameter' }, 'value' => { 'type' => 'string', 'description' => 'Value of parameter' } }
        },
        'ApiError' => {
          'type' => 'object',
          'properties' => { 'code' => { 'type' => 'integer', 'format' => 'int32', 'description' => 'status code' }, 'message' => { 'type' => 'string', 'description' => 'error message' } },
          'description' => 'ApiError model'
        },
        'Something' => {
          'type' => 'object',
          'properties' => {
            'id' => { 'type' => 'integer', 'format' => 'int32', 'description' => 'Identity of Something' },
            'text' => { 'type' => 'string', 'description' => 'Content of something.' },
            'links' => { 'type' => 'array', 'items' => { 'type' => 'link' } },
            'others' => { 'type' => 'text' }
          },
          'description' => 'Something model'
        }
      }
    }
  end

  let(:http_verbs) { %w[get post put delete] }
end

def mounted_paths
  %w[/thing /other_thing /dummy]
end
