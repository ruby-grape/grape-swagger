# frozen_string_literal: true

require 'spec_helper'

describe 'Links and Callbacks in OpenAPI 3.0' do
  describe 'Response links' do
    let(:spec) do
      GrapeSwagger::ApiModel::Spec.new.tap do |s|
        s.info = GrapeSwagger::ApiModel::Info.new(title: 'Test', version: '1.0')
      end
    end

    let(:response_with_links) do
      GrapeSwagger::ApiModel::Response.new.tap do |r|
        r.description = 'Successful response'
        r.links = {
          'GetUserById' => {
            'operationId' => 'getUser',
            'parameters' => {
              'userId' => '$response.body#/id'
            }
          }
        }
      end
    end

    let(:operation) do
      GrapeSwagger::ApiModel::Operation.new.tap do |op|
        op.operation_id = 'createUser'
        op.add_response('201', response_with_links)
      end
    end

    let(:path_item) do
      GrapeSwagger::ApiModel::PathItem.new.tap do |pi|
        pi.add_operation(:post, operation)
      end
    end

    before do
      spec.paths['/users'] = path_item
    end

    subject { GrapeSwagger::Exporter::OAS30.new(spec).export }

    it 'exports links in response' do
      response = subject[:paths]['/users'][:post][:responses]['201']
      expect(response[:links]).to be_present
    end

    it 'includes link with operationId' do
      links = subject[:paths]['/users'][:post][:responses]['201'][:links]
      expect(links['GetUserById']['operationId']).to eq('getUser')
    end

    it 'includes link parameters with runtime expressions' do
      links = subject[:paths]['/users'][:post][:responses]['201'][:links]
      expect(links['GetUserById']['parameters']['userId']).to eq('$response.body#/id')
    end
  end

  describe 'Operation callbacks' do
    let(:spec) do
      GrapeSwagger::ApiModel::Spec.new.tap do |s|
        s.info = GrapeSwagger::ApiModel::Info.new(title: 'Test', version: '1.0')
      end
    end

    let(:operation_with_callbacks) do
      GrapeSwagger::ApiModel::Operation.new.tap do |op|
        op.operation_id = 'createSubscription'
        op.callbacks = {
          'onData' => {
            '{$request.body#/callbackUrl}' => {
              'post' => {
                'requestBody' => {
                  'content' => {
                    'application/json' => {
                      'schema' => { 'type' => 'object' }
                    }
                  }
                },
                'responses' => {
                  '200' => { 'description' => 'Callback processed' }
                }
              }
            }
          }
        }
        op.add_response('201', GrapeSwagger::ApiModel::Response.new(description: 'Created'))
      end
    end

    let(:path_item) do
      GrapeSwagger::ApiModel::PathItem.new.tap do |pi|
        pi.add_operation(:post, operation_with_callbacks)
      end
    end

    before do
      spec.paths['/subscriptions'] = path_item
    end

    subject { GrapeSwagger::Exporter::OAS30.new(spec).export }

    it 'exports callbacks in operation' do
      operation = subject[:paths]['/subscriptions'][:post]
      expect(operation[:callbacks]).to be_present
    end

    it 'includes callback name' do
      callbacks = subject[:paths]['/subscriptions'][:post][:callbacks]
      expect(callbacks).to have_key('onData')
    end

    it 'includes callback URL expression' do
      callbacks = subject[:paths]['/subscriptions'][:post][:callbacks]
      expect(callbacks['onData']).to have_key('{$request.body#/callbackUrl}')
    end

    it 'includes callback operation' do
      callback_path = subject[:paths]['/subscriptions'][:post][:callbacks]['onData']['{$request.body#/callbackUrl}']
      expect(callback_path).to have_key('post')
      expect(callback_path['post']['responses']['200']['description']).to eq('Callback processed')
    end
  end

  describe 'Components links' do
    let(:spec) do
      GrapeSwagger::ApiModel::Spec.new.tap do |s|
        s.info = GrapeSwagger::ApiModel::Info.new(title: 'Test', version: '1.0')
      end
    end

    before do
      spec.components.links['GetUserById'] = {
        'operationId' => 'getUser',
        'parameters' => { 'userId' => '$response.body#/id' },
        'description' => 'Get the user by ID'
      }
    end

    subject { GrapeSwagger::Exporter::OAS30.new(spec).export }

    it 'exports links in components' do
      expect(subject[:components][:links]).to be_present
    end

    it 'includes link definition' do
      expect(subject[:components][:links]['GetUserById']['operationId']).to eq('getUser')
    end
  end

  describe 'Components callbacks' do
    let(:spec) do
      GrapeSwagger::ApiModel::Spec.new.tap do |s|
        s.info = GrapeSwagger::ApiModel::Info.new(title: 'Test', version: '1.0')
      end
    end

    before do
      spec.components.callbacks['onWebhook'] = {
        '{$request.body#/webhookUrl}' => {
          'post' => {
            'summary' => 'Webhook notification',
            'responses' => {
              '200' => { 'description' => 'OK' }
            }
          }
        }
      }
    end

    subject { GrapeSwagger::Exporter::OAS30.new(spec).export }

    it 'exports callbacks in components' do
      expect(subject[:components][:callbacks]).to be_present
    end

    it 'includes callback definition' do
      expect(subject[:components][:callbacks]['onWebhook']).to have_key('{$request.body#/webhookUrl}')
    end
  end
end
