# frozen_string_literal: true

require 'spec_helper'

describe 'license hash and custom schema_name_generator in Swagger 2.0' do
  describe 'license as a hash' do
    let(:app) do
      Class.new(Grape::API) do
        get('/x') { {} }
        add_swagger_documentation(info: { license: { name: 'MIT', url: 'https://opensource.org/licenses/MIT' } })
      end
    end

    it 'emits the license name and url' do
      get '/swagger_doc'
      expect(JSON.parse(last_response.body)['info']['license']).to eq(
        'name' => 'MIT', 'url' => 'https://opensource.org/licenses/MIT'
      )
    end
  end

  describe 'schema_name_generator' do
    let(:app) do
      Class.new(Grape::API) do
        get('/x') { {} }
        add_swagger_documentation
      end
    end

    around do |example|
      original = GrapeSwagger.instance_variable_get(:@schema_name_generator)
      GrapeSwagger.schema_name_generator = ->(model) { "Custom#{model.to_s.split('::').last}" }
      example.run
    ensure
      GrapeSwagger.instance_variable_set(:@schema_name_generator, original)
    end

    it 'names models through the configured generator' do
      stub_const('Pets', Module.new)
      stub_const('Pets::Dog', Class.new)

      expect(GrapeSwagger::DocMethods::DataType.parse_entity_name(Pets::Dog)).to eq('CustomDog')
    end
  end
end
