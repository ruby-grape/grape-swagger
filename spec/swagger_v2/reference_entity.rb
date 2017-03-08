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

        add_swagger_documentation # models: [MyAPI::Entities::Something, MyAPI::Entities::Kind]
      end
    end
  end

  def app
    MyAPI::ResponseModelApi
  end

  subject do
    get '/swagger_doc/kind'
    JSON.parse(last_response.body)
  end

  it 'should document specified models' do
    expect(subject['paths']['/kind']['get']['parameters']).to eq [{
      'in' => 'query',
      'name' => 'something',
      'description' => 'something as parameter',
      'type' => 'string',
      'required' => false,
      'allowMultiple' => false
    }]

    expect(subject['definitions'].keys).to include 'Something'
    expect(subject['definitions']['Something']).to eq(
      'type' => 'object', 'properties' => { 'text' => { 'type' => 'string' } }
    )

    expect(subject['definitions'].keys).to include 'Kind'
    expect(subject['definitions']['Kind']).to eq(
      'properties' => { 'something' => { '$ref' => '#/definitions/Something' } }
    )
  end
end
