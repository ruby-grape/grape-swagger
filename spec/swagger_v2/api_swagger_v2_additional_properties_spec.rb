# frozen_string_literal: true

require 'spec_helper'

describe 'parsing additional_parameters' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :things do
        class Element < Grape::Entity
          expose :id
        end

        params do
          optional :closed, type: Hash, documentation: { additional_properties: false, in: 'body' } do
            requires :only
          end
          optional :open, type: Hash, documentation: { additional_properties: true }
          optional :type_limited, type: Hash, documentation: { additional_properties: String }
          optional :ref_limited, type: Hash, documentation: { additional_properties: Element }
          optional :fallback, type: Hash, documentation: { additional_properties: { type: 'integer' } }
        end
        post do
          present params
        end
      end

      add_swagger_documentation format: :json, models: [Element]
    end
  end

  subject do
    get '/swagger_doc/things'
    JSON.parse(last_response.body)
  end

  describe 'POST' do
    specify do
      expect(subject.dig('paths', '/things', 'post', 'parameters')).to eql(
        [
          { 'name' => 'postThings', 'in' => 'body', 'required' => true, 'schema' => { '$ref' => '#/definitions/postThings' } }
        ]
      )
    end

    specify do
      expect(subject.dig('definitions', 'postThings')).to eql(
        'type' => 'object',
        'properties' => {
          'closed' => {
            'type' => 'object',
            'additionalProperties' => false,
            'properties' => {
              'only' => { 'type' => 'string' }
            },
            'required' => ['only']
          },
          'open' => {
            'type' => 'object',
            'additionalProperties' => true
          },
          'type_limited' => {
            'type' => 'object',
            'additionalProperties' => {
              'type' => 'string'
            }
          },
          'ref_limited' => {
            'type' => 'object',
            'additionalProperties' => {
              '$ref' => '#/definitions/Element'
            }
          },
          'fallback' => {
            'type' => 'object',
            'additionalProperties' => {
              'type' => 'integer'
            }
          }
        }
      )
    end
  end
end
