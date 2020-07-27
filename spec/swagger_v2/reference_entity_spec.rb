# frozen_string_literal: true

require 'spec_helper'

describe 'referenceEntity' do
  before :all do
    module MyAPI
      module Entities
        class Something < Grape::Entity
          def self.entity_name
            'SomethingCustom'
          end

          expose :text, documentation: { type: 'string', desc: 'Content of something.' }
        end

        class Kind < Grape::Entity
          def self.entity_name
            'KindCustom'
          end

          expose :title, documentation: { type: 'string', desc: 'Title of the kind.' }
          expose :something, documentation: { type: Something, desc: 'Something interesting.' }
        end

        class Base < Grape::Entity
          def self.entity_name
            parts = to_s.split('::')

            "MyAPI::#{parts.last}"
          end

          expose :title, documentation: { type: 'string', desc: 'Title of the parent.' }
        end

        class Child < Base
          expose :child, documentation: { type: 'string', desc: 'Child property.' }
        end
      end

      class ResponseModelApi < Grape::API
        format :json
        desc 'This returns kind and something or an error',
             params: Entities::Kind.documentation.slice(:something),
             entity: Entities::Kind,
             http_codes: [
               { code: 200, message: 'OK', model: Entities::Kind }
             ]
        params do
          optional :something, desc: 'something as parameter'
        end
        get '/kind' do
          kind = OpenStruct.new text: 'kind'
          present kind, with: Entities::Kind
        end

        desc 'This returns a child entity',
             entity: Entities::Child,
             http_codes: [
               { code: 200, message: 'OK', model: Entities::Child }
             ]
        get '/child' do
          child = OpenStruct.new text: 'child'
          present child, with: Entities::Child
        end

        add_swagger_documentation # models: [MyAPI::Entities::Something, MyAPI::Entities::Kind]
      end
    end
  end

  def app
    MyAPI::ResponseModelApi
  end

  describe 'kind' do
    subject do
      get '/swagger_doc/kind'
      JSON.parse(last_response.body)
    end

    it 'should document specified models' do
      expect(subject['paths']['/kind']['get']['parameters']).to eq [{
        'in' => 'query',
        'name' => 'something',
        'description' => 'Something interesting.',
        'type' => 'SomethingCustom',
        'required' => false
      }]

      expect(subject['definitions'].keys).to include 'SomethingCustom'
      expect(subject['definitions']['SomethingCustom']).to eq(
        'type' => 'object', 'properties' => { 'text' => { 'type' => 'string', 'description' => 'Content of something.' } }
      )

      expect(subject['definitions'].keys).to include 'KindCustom'
      expect(subject['definitions']['KindCustom']).to eq(
        'type' => 'object',
        'properties' => {
          'title' => { 'type' => 'string', 'description' => 'Title of the kind.' },
          'something' => {
            '$ref' => '#/definitions/SomethingCustom',
            'description' => 'Something interesting.'
          }
        },
        'description' => 'KindCustom model'
      )
    end
  end

  describe 'child' do
    subject do
      get '/swagger_doc/child'
      JSON.parse(last_response.body)
    end

    it 'should document specified models' do
      expect(subject['definitions'].keys).to include 'MyAPI::Child'
      expect(subject['definitions']['MyAPI::Child']).to eq(
        'type' => 'object',
        'properties' => {
          'title' => { 'type' => 'string', 'description' => 'Title of the parent.' },
          'child' => { 'type' => 'string', 'description' => 'Child property.' }
        },
        'description' => 'MyAPI::Child model'
      )
    end
  end
end
