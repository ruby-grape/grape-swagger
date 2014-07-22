require 'spec_helper'

describe 'Global Models' do

  before :all do
    module Entities
      module Some
        class Thing < Grape::Entity
          expose :text, documentation: { type: 'string', desc: 'Content of something.' }
        end
      end
    end
  end

  subject do
    Class.new(Grape::API) do
      desc 'This gets thing.', params: Entities::Some::Thing.documentation
      get '/thing' do
        thing = OpenStruct.new text: 'thing'
        present thing, with: Entities::Some::Thing
      end

      add_swagger_documentation models: [Entities::Some::Thing]
    end
  end

  def app
    subject
  end

  it 'includes models specified' do
    get '/swagger_doc/thing.json'
    json = JSON.parse(last_response.body)
    expect(json['models']).to eq(
        'Some::Thing' => {
          'id' => 'Some::Thing',
          'properties' => {
            'text' => { 'type' => 'string', 'description' => 'Content of something.' }
          }
        })
  end
end
