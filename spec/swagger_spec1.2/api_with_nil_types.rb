require 'spec_helper'

describe 'API with minimally documented models' do
  def app
    entity_klass = Class.new do
      def self.exposures
        {}
      end

      def self.documentation
        {
          bar: { type: String },
          foo: {}
        }
      end

      def self.entity_name
        'Foo'
      end
    end

    Class.new(Grape::API) do
      format :json

      get :foo do
      end

      add_swagger_documentation \
        format: :json,
        models: [Class.new(entity_klass)]
    end
  end

  subject do
    get '/swagger_doc/foo'
    JSON.parse(last_response.body)['models']
  end

  it 'returns model' do
    expect(subject).to eq(
      'Foo' => {
        'id' => 'Foo',
        'properties' => {
          'bar' => { 'type' => 'string' },
          'foo' => { '$ref' => nil }
        }
      }
    )
  end
end
