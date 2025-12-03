# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1 Configuration Options' do
  describe 'json_schema_dialect option' do
    before :all do
      module JsonSchemaDialectTest
        class API < Grape::API
          format :json

          desc 'Simple endpoint'
          get '/test' do
            { status: 'ok' }
          end

          add_swagger_documentation(
            openapi_version: '3.1',
            json_schema_dialect: 'https://json-schema.org/draft/2020-12/schema'
          )
        end
      end
    end

    def app
      JsonSchemaDialectTest::API
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes jsonSchemaDialect in output' do
      expect(subject['jsonSchemaDialect']).to eq('https://json-schema.org/draft/2020-12/schema')
    end

    it 'places jsonSchemaDialect after openapi version' do
      keys = subject.keys
      expect(keys.index('jsonSchemaDialect')).to be < keys.index('info')
    end
  end

  describe 'json_schema_dialect ignored in OAS 3.0' do
    before :all do
      module JsonSchemaDialect30Test
        class API < Grape::API
          format :json

          desc 'Simple endpoint'
          get '/test' do
            { status: 'ok' }
          end

          add_swagger_documentation(
            openapi_version: '3.0',
            json_schema_dialect: 'https://json-schema.org/draft/2020-12/schema'
          )
        end
      end
    end

    def app
      JsonSchemaDialect30Test::API
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'does not include jsonSchemaDialect in OAS 3.0' do
      expect(subject).not_to have_key('jsonSchemaDialect')
    end
  end

  describe 'webhooks option' do
    before :all do
      module WebhooksTest
        class API < Grape::API
          format :json

          desc 'Simple endpoint'
          get '/test' do
            { status: 'ok' }
          end

          add_swagger_documentation(
            openapi_version: '3.1',
            webhooks: {
              newPetAvailable: {
                post: {
                  summary: 'New pet available',
                  description: 'A new pet has been added to the store',
                  operationId: 'newPetWebhook',
                  tags: ['pets'],
                  requestBody: {
                    required: true,
                    content: {
                      'application/json': {
                        schema: {
                          type: 'object',
                          properties: {
                            petId: { type: 'integer', description: 'Pet ID' },
                            petName: { type: 'string', description: 'Pet name' }
                          },
                          required: %w[petId petName]
                        }
                      }
                    }
                  },
                  responses: {
                    '200': { description: 'Webhook received successfully' },
                    '400': { description: 'Invalid payload' }
                  }
                }
              },
              orderStatusChanged: {
                post: {
                  summary: 'Order status changed',
                  description: 'An order status has been updated',
                  responses: {
                    '200': { description: 'OK' }
                  }
                }
              }
            }
          )
        end
      end
    end

    def app
      WebhooksTest::API
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes webhooks section' do
      expect(subject).to have_key('webhooks')
    end

    it 'has all defined webhooks' do
      webhooks = subject['webhooks']
      expect(webhooks).to have_key('newPetAvailable')
      expect(webhooks).to have_key('orderStatusChanged')
    end

    describe 'newPetAvailable webhook' do
      let(:webhook) { subject['webhooks']['newPetAvailable'] }
      let(:operation) { webhook['post'] }

      it 'has correct summary' do
        expect(operation['summary']).to eq('New pet available')
      end

      it 'has correct description' do
        expect(operation['description']).to eq('A new pet has been added to the store')
      end

      it 'has operationId' do
        expect(operation['operationId']).to eq('newPetWebhook')
      end

      it 'has tags' do
        expect(operation['tags']).to eq(['pets'])
      end

      it 'has requestBody' do
        expect(operation['requestBody']).to be_present
        expect(operation['requestBody']['required']).to be true
      end

      it 'has requestBody content with schema' do
        content = operation['requestBody']['content']['application/json']
        expect(content['schema']['type']).to eq('object')
        expect(content['schema']['properties']).to have_key('petId')
        expect(content['schema']['properties']).to have_key('petName')
      end

      it 'has responses' do
        expect(operation['responses']).to have_key('200')
        expect(operation['responses']).to have_key('400')
      end
    end

    describe 'orderStatusChanged webhook' do
      let(:webhook) { subject['webhooks']['orderStatusChanged'] }
      let(:operation) { webhook['post'] }

      it 'has correct summary' do
        expect(operation['summary']).to eq('Order status changed')
      end

      it 'has responses' do
        expect(operation['responses']['200']['description']).to eq('OK')
      end
    end
  end

  describe 'webhooks ignored in OAS 3.0' do
    before :all do
      module Webhooks30Test
        class API < Grape::API
          format :json

          desc 'Simple endpoint'
          get '/test' do
            { status: 'ok' }
          end

          add_swagger_documentation(
            openapi_version: '3.0',
            webhooks: {
              testWebhook: {
                post: {
                  summary: 'Test webhook',
                  responses: { '200': { description: 'OK' } }
                }
              }
            }
          )
        end
      end
    end

    def app
      Webhooks30Test::API
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'does not include webhooks in OAS 3.0' do
      expect(subject).not_to have_key('webhooks')
    end
  end

  describe 'webhooks with schema reference' do
    before :all do
      module WebhooksRefTest
        module Entities
          class Pet < Grape::Entity
            expose :id, documentation: { type: Integer, required: true }
            expose :name, documentation: { type: String, required: true }
          end
        end

        class API < Grape::API
          format :json

          desc 'Get pet', success: Entities::Pet
          get '/pet' do
            { id: 1, name: 'Fluffy' }
          end

          add_swagger_documentation(
            openapi_version: '3.1',
            webhooks: {
              petCreated: {
                post: {
                  summary: 'Pet created',
                  requestBody: {
                    required: true,
                    content: {
                      'application/json': {
                        schema: { '$ref': '#/components/schemas/Pet' }
                      }
                    }
                  },
                  responses: {
                    '200': { description: 'OK' }
                  }
                }
              }
            }
          )
        end
      end
    end

    def app
      WebhooksRefTest::API
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes webhook with schema reference' do
      webhook = subject['webhooks']['petCreated']
      content = webhook['post']['requestBody']['content']['application/json']
      expect(content['schema']['$ref']).to eq('#/components/schemas/Pet')
    end
  end

  describe 'combined OAS 3.1 options' do
    before :all do
      module CombinedOAS31Test
        class API < Grape::API
          format :json

          desc 'Simple endpoint'
          get '/test' do
            { status: 'ok' }
          end

          add_swagger_documentation(
            openapi_version: '3.1',
            info: {
              title: 'Combined Test API',
              license: { name: 'MIT', identifier: 'MIT' }
            },
            json_schema_dialect: 'https://json-schema.org/draft/2020-12/schema',
            webhooks: {
              testEvent: {
                post: {
                  summary: 'Test event',
                  responses: { '200': { description: 'OK' } }
                }
              }
            }
          )
        end
      end
    end

    def app
      CombinedOAS31Test::API
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'has openapi 3.1.0 version' do
      expect(subject['openapi']).to eq('3.1.0')
    end

    it 'has jsonSchemaDialect' do
      expect(subject['jsonSchemaDialect']).to eq('https://json-schema.org/draft/2020-12/schema')
    end

    it 'has webhooks' do
      expect(subject['webhooks']).to have_key('testEvent')
    end

    it 'has license with identifier' do
      expect(subject['info']['license']['identifier']).to eq('MIT')
    end

    it 'does not have license url when identifier is present' do
      expect(subject['info']['license']).not_to have_key('url')
    end
  end
end
