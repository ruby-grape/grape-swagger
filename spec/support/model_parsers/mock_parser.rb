# frozen_string_literal: true

RSpec.shared_context 'mock swagger example' do
  before :all do
    module Entities
      class Something < OpenStruct
        class << self
          # Representable doesn't have documentation method, mock this
          def documentation
            {
              id: { type: Integer, desc: 'Identity of Something' },
              text: { type: String, desc: 'Content of something.' },
              links: { type: 'link', is_array: true },
              others: { type: 'text', is_array: false }
            }
          end
        end
      end

      class UseResponse < OpenStruct
        class << self
          def documentation
            {
              :description => { type: String },
              '$responses' => { is_array: true }
            }
          end
        end
      end

      class ResponseItem < OpenStruct
        class << self
          def documentation
            {
              id: { type: Integer },
              name: { type: String }
            }
          end
        end
      end

      class UseNestedWithAddress < OpenStruct; end
      class TypedDefinition < OpenStruct; end
      class UseItemResponseAsType < OpenStruct; end
      class OtherItem < OpenStruct; end
      class EnumValues < OpenStruct; end
      class AliasedThing < OpenStruct; end
      class FourthLevel < OpenStruct; end
      class ThirdLevel < OpenStruct; end
      class SecondLevel < OpenStruct; end
      class FirstLevel < OpenStruct; end
      class QueryInputElement < OpenStruct; end
      class QueryInput < OpenStruct; end
      class ApiError < OpenStruct; end
      class SecondApiError < OpenStruct; end
      class RecursiveModel < OpenStruct; end
      class DocumentedHashAndArrayModel < OpenStruct; end
      module NestedModule
        class ApiResponse < OpenStruct; end
      end
    end
  end

  let(:swagger_definitions_models) do
    {
      'ApiError' => {
        'type' => 'object',
        'properties' => {
          'mock_data' => {
            'type' => 'string',
            'description' => "it's a mock"
          }
        }
      },
      'RecursiveModel' => {
        'type' => 'object',
        'properties' => {
          'mock_data' => {
            'type' => 'string',
            'description' => "it's a mock"
          }
        }
      },
      'UseResponse' => {
        'type' => 'object',
        'properties' => {
          'mock_data' => {
            'type' => 'string',
            'description' => "it's a mock"
          }
        }
      },
      'DocumentedHashAndArrayModel' => {
        'type' => 'object',
        'properties' => {
          'mock_data' => {
            'type' => 'string',
            'description' => "it's a mock"
          }
        }
      }
    }
  end

  let(:swagger_nested_type) do
    {
      'ApiError' => {
        'type' => 'object',
        'properties' => {
          'mock_data' => {
            'type' => 'string',
            'description' => "it's a mock"
          }
        },
        'description' => 'This returns something'
      },
      'UseItemResponseAsType' => {
        'type' => 'object',
        'properties' => {
          'mock_data' => {
            'type' => 'string',
            'description' => "it's a mock"
          }
        },
        'description' => 'This returns something'
      }
    }
  end

  let(:swagger_entity_as_response_object) do
    {
      'UseResponse' => {
        'type' => 'object',
        'properties' => {
          'mock_data' => {
            'type' => 'string',
            'description' => "it's a mock"
          }
        },
        'description' => 'This returns something'
      },
      'ApiError' => {
        'type' => 'object',
        'properties' => {
          'mock_data' => {
            'type' => 'string',
            'description' => "it's a mock"
          }
        },
        'description' => 'This returns something'
      }
    }
  end

  let(:swagger_params_as_response_object) do
    {
      'ApiError' => {
        'type' => 'object',
        'properties' => {
          'mock_data' => {
            'type' => 'string',
            'description' => "it's a mock"
          }
        },
        'description' => 'This returns something'
      }
    }
  end

  let(:swagger_typed_defintion) do
    {
      'mock_data' => {
        'type' => 'string',
        'description' => "it's a mock"
      }
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
          'properties' => {
            'mock_data' => {
              'type' => 'string',
              'description' => "it's a mock"
            }
          },
          'description' => 'nested route inside namespace'
        },
        'ApiError' => {
          'type' => 'object',
          'properties' => {
            'mock_data' => {
              'type' => 'string',
              'description' => "it's a mock"
            }
          },
          'description' => 'This gets Things.'
        },
        'Something' => {
          'type' => 'object',
          'properties' => {
            'mock_data' => {
              'type' => 'string',
              'description' => "it's a mock"
            }
          },
          'description' => 'This gets Things.'
        }
      }
    }
  end

  let(:http_verbs) { %w[get post put delete] }
end

def mounted_paths
  %w[/thing /other_thing /dummy]
end
