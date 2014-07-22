require 'spec_helper'

describe 'responseModel' do
  before :all do
    module MyAPI
      module Entities
        class BaseEntity < Grape::Entity
          def self.entity_name
            name.sub(/^MyAPI::Entities::/, '')
          end
        end

        class Something < BaseEntity
          expose :text, documentation: { type: 'string', desc: 'Content of something.' }
        end

        class Error < BaseEntity
          expose :code, documentation: { type: 'string', desc: 'Error code' }
          expose :message, documentation: { type: 'string', desc: 'Error message' }
        end
      end

      class ResponseModelApi < Grape::API
        format :json
        desc 'This returns something or an error',
             entity: Entities::Something,
             http_codes: [
               [200, 'OK', Entities::Something],
               [403, 'Refused to return something', Entities::Error]
             ]

        get '/something/:id' do
          if params[:id] == 1
            something = OpenStruct.new text: 'something'
            present something, with: Entities::Something
          else
            error = OpenStruct.new code: 'some_error', message: 'Some error'
            present error, with: Entities::Error
          end
        end

        add_swagger_documentation
      end
    end
  end

  def app
    MyAPI::ResponseModelApi
  end

  subject do
    get '/swagger_doc/something'
    JSON.parse(last_response.body)
  end

  it 'should document specified models' do
    expect(subject['apis'][0]['operations'][0]['responseMessages']).to eq(
      [
        {
          'code' => 200,
          'message' => 'OK',
          'responseModel' => 'Something'
        },
        {
          'code' => 403,
          'message' => 'Refused to return something',
          'responseModel' => 'Error'
        }
      ]
    )
    expect(subject['models'].keys).to include 'Error'
    expect(subject['models']['Error']).to eq(
      'id' => 'Error',
      'properties' => {
        'code' => { 'type' => 'string', 'description' => 'Error code' },
        'message' => { 'type' => 'string', 'description' => 'Error message' }
      }
    )
  end
end
