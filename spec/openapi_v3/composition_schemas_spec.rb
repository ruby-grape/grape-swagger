# frozen_string_literal: true

require 'spec_helper'

describe 'SchemaBuilder composition support' do
  let(:definitions) { {} }
  let(:builder) { GrapeSwagger::OpenAPI::Builder::SchemaBuilder.new(definitions) }

  describe '#build_from_definition with allOf' do
    let(:definition) do
      {
        allOf: [
          { '$ref' => '#/definitions/BaseModel' },
          { type: 'object', properties: { name: { type: 'string' } } }
        ]
      }
    end

    it 'creates schema with all_of array' do
      schema = builder.build_from_definition(definition)

      expect(schema.all_of).to be_an(Array)
      expect(schema.all_of.length).to eq(2)

      # First element is a reference
      expect(schema.all_of[0].canonical_name).to eq('BaseModel')

      # Second element is an inline schema
      expect(schema.all_of[1].type).to eq('object')
      expect(schema.all_of[1].properties).to have_key('name')
    end
  end

  describe '#build_from_definition with oneOf' do
    let(:definition) do
      {
        oneOf: [
          { '$ref' => '#/definitions/Cat' },
          { '$ref' => '#/definitions/Dog' }
        ]
      }
    end

    it 'creates schema with one_of array' do
      schema = builder.build_from_definition(definition)

      expect(schema.one_of).to be_an(Array)
      expect(schema.one_of.length).to eq(2)
      expect(schema.one_of[0].canonical_name).to eq('Cat')
      expect(schema.one_of[1].canonical_name).to eq('Dog')
    end
  end

  describe '#build_from_definition with anyOf' do
    let(:definition) do
      {
        anyOf: [
          { type: 'string' },
          { type: 'integer' }
        ]
      }
    end

    it 'creates schema with any_of array' do
      schema = builder.build_from_definition(definition)

      expect(schema.any_of).to be_an(Array)
      expect(schema.any_of.length).to eq(2)
      expect(schema.any_of[0].type).to eq('string')
      expect(schema.any_of[1].type).to eq('integer')
    end
  end

  describe '#build_from_definition with nested composition' do
    let(:definition) do
      {
        oneOf: [
          {
            allOf: [
              { '$ref' => '#/definitions/Base' },
              { type: 'object', properties: { catName: { type: 'string' } } }
            ]
          },
          {
            allOf: [
              { '$ref' => '#/definitions/Base' },
              { type: 'object', properties: { dogName: { type: 'string' } } }
            ]
          }
        ]
      }
    end

    it 'creates nested composition schemas' do
      schema = builder.build_from_definition(definition)

      expect(schema.one_of).to be_an(Array)
      expect(schema.one_of.length).to eq(2)

      # First oneOf option has allOf
      expect(schema.one_of[0].all_of).to be_an(Array)
      expect(schema.one_of[0].all_of.length).to eq(2)
      expect(schema.one_of[0].all_of[0].canonical_name).to eq('Base')
      expect(schema.one_of[0].all_of[1].properties).to have_key('catName')

      # Second oneOf option has allOf
      expect(schema.one_of[1].all_of).to be_an(Array)
      expect(schema.one_of[1].all_of[0].canonical_name).to eq('Base')
      expect(schema.one_of[1].all_of[1].properties).to have_key('dogName')
    end
  end
end

describe 'OAS30 exporter composition support' do
  let(:spec) do
    GrapeSwagger::OpenAPI::Document.new.tap do |s|
      s.info = GrapeSwagger::OpenAPI::Info.new(title: 'Test', version: '1.0')
    end
  end

  let(:schema_with_one_of) do
    GrapeSwagger::OpenAPI::Schema.new.tap do |s|
      s.one_of = [
        GrapeSwagger::OpenAPI::Schema.new(canonical_name: 'Cat'),
        GrapeSwagger::OpenAPI::Schema.new(canonical_name: 'Dog')
      ]
    end
  end

  let(:schema_with_any_of) do
    GrapeSwagger::OpenAPI::Schema.new.tap do |s|
      s.any_of = [
        GrapeSwagger::OpenAPI::Schema.new(type: 'string'),
        GrapeSwagger::OpenAPI::Schema.new(type: 'integer')
      ]
    end
  end

  let(:schema_with_all_of) do
    GrapeSwagger::OpenAPI::Schema.new.tap do |s|
      s.all_of = [
        GrapeSwagger::OpenAPI::Schema.new(canonical_name: 'Base'),
        GrapeSwagger::OpenAPI::Schema.new(type: 'object').tap do |obj|
          obj.add_property('extra', GrapeSwagger::OpenAPI::Schema.new(type: 'string'))
        end
      ]
    end
  end

  before do
    spec.components.add_schema('Pet', schema_with_one_of)
    spec.components.add_schema('Value', schema_with_any_of)
    spec.components.add_schema('ExtendedBase', schema_with_all_of)
  end

  subject { GrapeSwagger::Exporter::OAS30.new(spec).export }

  it 'exports oneOf with schema references' do
    pet_schema = subject[:components][:schemas]['Pet']

    expect(pet_schema[:oneOf]).to be_an(Array)
    expect(pet_schema[:oneOf].length).to eq(2)
    expect(pet_schema[:oneOf][0]).to eq({ '$ref' => '#/components/schemas/Cat' })
    expect(pet_schema[:oneOf][1]).to eq({ '$ref' => '#/components/schemas/Dog' })
  end

  it 'exports anyOf with inline schemas' do
    value_schema = subject[:components][:schemas]['Value']

    expect(value_schema[:anyOf]).to be_an(Array)
    expect(value_schema[:anyOf].length).to eq(2)
    expect(value_schema[:anyOf][0]).to eq({ type: 'string' })
    expect(value_schema[:anyOf][1]).to eq({ type: 'integer' })
  end

  it 'exports allOf with mixed refs and inline schemas' do
    extended_schema = subject[:components][:schemas]['ExtendedBase']

    expect(extended_schema[:allOf]).to be_an(Array)
    expect(extended_schema[:allOf].length).to eq(2)
    expect(extended_schema[:allOf][0]).to eq({ '$ref' => '#/components/schemas/Base' })
    expect(extended_schema[:allOf][1]).to eq({
      type: 'object',
      properties: { 'extra' => { type: 'string' } }
    })
  end
end
