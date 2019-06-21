# frozen_string_literal: true

require 'spec_helper'

describe 'a simple mounted api' do
  before :all do
    class CustomType; end

    class SimpleMountedApi < Grape::API
      desc 'Document root'
      get do
      end

      desc 'This gets something.',
           notes: '_test_'

      get '/simple' do
        { bla: 'something' }
      end

      desc 'This gets something for URL using - separator.',
           notes: '_test_'

      get '/simple-test' do
        { bla: 'something' }
      end

      head '/simple-head-test' do
        status 200
      end

      options '/simple-options-test' do
        status 200
      end

      desc 'this gets something else',
           headers: {
             'XAuthToken' => { description: 'A required header.', required: true },
             'XOtherHeader' => { description: 'An optional header.', required: false }
           },
           http_codes: [
             { code: 403, message: 'invalid pony' },
             { code: 405, message: 'no ponies left!' }
           ]

      get '/simple_with_headers' do
        { bla: 'something_else' }
      end

      desc 'this takes an array of parameters',
           params: {
             'items[]' => { description: 'array of items', is_array: true }
           }

      post '/items' do
        {}
      end

      desc 'this uses a custom parameter',
           params: {
             'custom' => { type: CustomType, description: 'array of items', is_array: true }
           }

      post '/custom' do
        {}
      end
    end

    class SimpleApi < Grape::API
      mount SimpleMountedApi
      add_swagger_documentation openapi_version: '3.0', servers: {
        url: 'http://example.org'
      }
    end
  end

  def app
    SimpleApi
  end

  describe 'retrieves swagger-documentation on /swagger_doc' do
    subject do
      get '/swagger_doc.json'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject).to eq(
        'info' => {
          'title' => 'API title', 'version' => '0.0.1'
        },
        'openapi' => '3.0.0',
        'servers' => [
          'url' => 'http://example.org'
        ],
        'tags' => [
          { 'name' => 'simple', 'description' => 'Operations about simples' },
          { 'name' => 'simple-test', 'description' => 'Operations about simple-tests' },
          { 'name' => 'simple-head-test', 'description' => 'Operations about simple-head-tests' },
          { 'name' => 'simple-options-test', 'description' => 'Operations about simple-options-tests' },
          { 'name' => 'simple_with_headers', 'description' => 'Operations about simple_with_headers' },
          { 'name' => 'items', 'description' => 'Operations about items' },
          { 'name' => 'custom', 'description' => 'Operations about customs' }
        ],
        'paths' => {
          '/' => {
            'get' => {
              'description' => 'Document root',
              'responses' => { '200' => { 'content' => { 'application/json' => {} }, 'description' => 'Document root' } },
              'operationId' => 'get'
            }
          },
          '/simple' => {
            'get' => {
              'description' => 'This gets something.',
              'tags' => ['simple'],
              'operationId' => 'getSimple',
              'responses' => { '200' => { 'content' => { 'application/json' => {} }, 'description' => 'This gets something.' } }
            }
          },
          '/simple-test' => {
            'get' => {
              'description' => 'This gets something for URL using - separator.',
              'tags' => ['simple-test'],
              'operationId' => 'getSimpleTest',
              'responses' => { '200' => { 'content' => { 'application/json' => {} }, 'description' => 'This gets something for URL using - separator.' } }
            }
          },
          '/simple-head-test' => {
            'head' => {
              'responses' => { '200' => { 'content' => { 'application/json' => {} }, 'description' => 'head SimpleHeadTest' } },
              'tags' => ['simple-head-test'],
              'operationId' => 'headSimpleHeadTest'
            }
          },
          '/simple-options-test' => {
            'options' => {
              'responses' => {
                '200' => { 'content' => { 'application/json' => {} },
                           'description' => 'option SimpleOptionsTest' }
              },
              'tags' => ['simple-options-test'],
              'operationId' => 'optionsSimpleOptionsTest'
            }
          },
          '/simple_with_headers' => {
            'get' => {
              'description' => 'this gets something else',
              'operationId' => 'getSimpleWithHeaders',
              'parameters' => [
                { 'description' => 'A required header.',
                  'in' => 'header',
                  'name' => 'XAuthToken',
                  'required' => true,
                  'schema' => { 'type' => 'string' } },
                {
                  'description' => 'An optional header.',
                  'in' => 'header',
                  'name' => 'XOtherHeader',
                  'required' => false,
                  'schema' => { 'type' => 'string' }
                }
              ],
              'responses' => { '200' => { 'content' => { 'application/json' => {} },
                                          'description' => 'this gets something else' },
                               '403' => { 'content' => { 'application/json' => {} },
                                          'description' => 'invalid pony' },
                               '405' => { 'content' => { 'application/json' => {} },
                                          'description' => 'no ponies left!' } },
              'tags' => ['simple_with_headers']
            }
          },
          '/custom' => {
            'post' => {
              'description' => 'this uses a custom parameter',
              'operationId' => 'postCustom',
              'requestBody' => {
                'content' => {
                  'application/json' => { 'schema' => { 'properties' => {}, 'type' => 'object' } },
                  'application/x-www-form-urlencoded' => {
                    'schema' => {
                      'properties' => {
                        'custom' => {
                          'description' => 'array of items',
                          'items' => { 'type' => 'CustomType' },
                          'type' => 'array'
                        }
                      },
                      'type' => 'object'
                    }
                  }
                }
              }, 'responses' => { '201' => { 'description' => 'this uses a custom parameter' } }, 'tags' => ['custom']
            }
          },
          '/items' => {
            'post' => {
              'description' => 'this takes an array of parameters',
              'operationId' => 'postItems',
              'requestBody' => {
                'content' => {
                  'application/json' => { 'schema' => { 'properties' => {}, 'type' => 'object' } },
                  'application/x-www-form-urlencoded' => {
                    'schema' => {
                      'properties' => {
                        'items[]' => {
                          'description' => 'array of items',
                          'items' => { 'type' => 'string' },
                          'type' => 'array'
                        }
                      }, 'type' => 'object'
                    }
                  }
                }
              },
              'responses' => {
                '201' => { 'description' => 'this takes an array of parameters' }
              },
              'tags' => ['items']
            }
          }
        }
      )
    end
  end

  describe 'retrieves the documentation for mounted-api' do
    subject do
      get '/swagger_doc/simple.json'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject).to eq(
        'info' => { 'title' => 'API title', 'version' => '0.0.1' },
        'openapi' => '3.0.0',
        # 'produces' => ['application/xml', 'application/json', 'application/octet-stream', 'text/plain'],
        'servers' => [
          'url' => 'http://example.org'
        ],
        'tags' => [
          { 'name' => 'simple', 'description' => 'Operations about simples' }
        ],
        'paths' => {
          '/simple' => {
            'get' => {
              'description' => 'This gets something.',
              'tags' => ['simple'],
              'operationId' => 'getSimple',
              'responses' => { '200' => { 'content' => { 'application/json' => {} }, 'description' => 'This gets something.' } }
            }
          }
        }
      )
    end
  end

  describe 'retrieves the documentation for mounted-api that' do
    describe "contains '-' in URL" do
      subject do
        get '/swagger_doc/simple-test.json'
        JSON.parse(last_response.body)
      end

      specify do
        expect(subject).to eq(
          'info' => { 'title' => 'API title', 'version' => '0.0.1' },
          'openapi' => '3.0.0',
          # 'produces' => ['application/xml', 'application/json', 'application/octet-stream', 'text/plain'],
          'servers' => [
            'url' => 'http://example.org'
          ],
          'tags' => [
            { 'name' => 'simple-test', 'description' => 'Operations about simple-tests' }
          ],
          'paths' => {
            '/simple-test' => {
              'get' => {
                'description' => 'This gets something for URL using - separator.',
                'tags' => ['simple-test'],
                'operationId' => 'getSimpleTest',
                'responses' => { '200' => { 'content' => { 'application/json' => {} }, 'description' => 'This gets something for URL using - separator.' } }
              }
            }
          }
        )
      end
    end

    describe 'includes headers' do
      subject do
        get '/swagger_doc/simple_with_headers.json'
        JSON.parse(last_response.body)
      end

      specify do
        expect(subject['paths']).to eq(
          '/simple_with_headers' => {
            'get' => {
              'description' => 'this gets something else',
              'parameters' => [
                { 'in' => 'header', 'name' => 'XAuthToken', 'description' => 'A required header.', 'schema' => { 'type' => 'string' }, 'required' => true },
                { 'in' => 'header', 'name' => 'XOtherHeader', 'description' => 'An optional header.', 'schema' => { 'type' => 'string' }, 'required' => false }
              ],
              'tags' => ['simple_with_headers'],
              'operationId' => 'getSimpleWithHeaders',
              'responses' => {
                '200' => { 'content' => { 'application/json' => {} }, 'description' => 'this gets something else' },
                '403' => { 'content' => { 'application/json' => {} }, 'description' => 'invalid pony' },
                '405' => { 'content' => { 'application/json' => {} }, 'description' => 'no ponies left!' }
              }
            }
          }
        )
      end
    end

    describe 'supports array params' do
      subject do
        get '/swagger_doc/items.json'
        JSON.parse(last_response.body)
      end

      specify do
        expect(subject['paths']).to eq(
          '/items' => {
            'post' => {
              'description' => 'this takes an array of parameters',
              'requestBody' => {
                'content' => {
                  'application/json' => { 'schema' => { 'properties' => {}, 'type' => 'object' } },
                  'application/x-www-form-urlencoded' => {
                    'schema' => {
                      'properties' => {
                        'items[]' => {
                          'description' => 'array of items',
                          'items' => { 'type' => 'string' },
                          'type' => 'array'
                        }
                      },
                      'type' => 'object'
                    }
                  }
                }
              },
              'tags' => ['items'],
              'operationId' => 'postItems',
              'responses' => { '201' => { 'description' => 'this takes an array of parameters' } }
            }
          }
        )
      end
    end

    # TODO: Rendering a custom param type the way it is done here is not valid OpenAPI
    # (nor I believe it is valid Swagger 2.0). We should render such a type with a JSON reference
    # under components/schemas.
    describe 'supports custom params types' do
      subject do
        get '/swagger_doc/custom.json'
        JSON.parse(last_response.body)
      end

      specify do
        expect(subject['paths']).to eq(
          '/custom' => {
            'post' => {
              'description' => 'this uses a custom parameter',
              'operationId' => 'postCustom',
              'requestBody' => {
                'content' => {
                  'application/json' => { 'schema' => { 'properties' => {}, 'type' => 'object' } },
                  'application/x-www-form-urlencoded' => {
                    'schema' => {
                      'properties' => {
                        'custom' => {
                          'description' => 'array of items',
                          'items' => { 'type' => 'CustomType' },
                          'type' => 'array'
                        }
                      },
                      'type' => 'object'
                    }
                  }
                }
              }, 'responses' => { '201' => { 'description' => 'this uses a custom parameter' } }, 'tags' => ['custom']
            }
          }
        )
      end
    end
  end
end
