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
               [200, 'OK', Entities::Kind]
             ]

        get '/kind' do
          kind = OpenStruct.new text: 'kind'
          present kind, with: Entities::Kind
        end

        add_swagger_documentation models: [MyAPI::Entities::Something, MyAPI::Entities::Kind]
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
    expect(subject['apis'][0]['operations'][0]['parameters']).to eq [{
      'paramType' => 'query',
      'name' => 'something',
      'description' => 'Something interesting.',
      'type' => 'MySomething',
      'required' => false,
      'allowMultiple' => false
    }]

    expect(subject['models'].keys).to include 'MySomething'
    expect(subject['models']['MySomething']).to eq(
      'id' => 'MyAPI::Something',
      'properties' => {
        'text' => { 'type' => 'string', 'description' => 'Content of something.' }
      }
    )

    expect(subject['models'].keys).to include 'MyKind'
    expect(subject['models']['MyKind']).to eq(
      'id' => 'MyKind',
      'properties' => {
        'title' => { 'type' => 'string', 'description' => 'Title of the kind.' },
        'something' => { '$ref' => 'MySomething', 'description' => 'Something interesting.' }
      }
    )
  end
end
