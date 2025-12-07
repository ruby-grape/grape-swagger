# frozen_string_literal: true

require 'spec_helper'

describe 'Discriminator in OpenAPI 3.0' do
  describe 'SchemaBuilder preserves discriminator' do
    let(:definitions) { {} }
    let(:builder) { GrapeSwagger::OpenAPI::Builder::SchemaBuilder.new(definitions) }

    it 'preserves discriminator field from definition' do
      definition = {
        type: 'object',
        properties: {
          type: { type: 'string' },
          name: { type: 'string' }
        },
        discriminator: 'type'
      }

      schema = builder.build_from_definition(definition)

      expect(schema.discriminator).to eq('type')
    end
  end

  describe 'OAS30 exporter handles discriminator' do
    let(:spec) do
      GrapeSwagger::OpenAPI::Document.new.tap do |s|
        s.info = GrapeSwagger::OpenAPI::Info.new(title: 'Test', version: '1.0')
      end
    end

    let(:pet_schema) do
      GrapeSwagger::OpenAPI::Schema.new.tap do |s|
        s.type = 'object'
        s.discriminator = 'type'
        s.add_property('type', GrapeSwagger::OpenAPI::Schema.new(type: 'string'))
        s.add_property('name', GrapeSwagger::OpenAPI::Schema.new(type: 'string'))
        s.mark_required('type')
        s.mark_required('name')
      end
    end

    let(:cat_schema) do
      GrapeSwagger::OpenAPI::Schema.new.tap do |s|
        s.all_of = [
          GrapeSwagger::OpenAPI::Schema.new(canonical_name: 'Pet'),
          GrapeSwagger::OpenAPI::Schema.new(type: 'object').tap do |props|
            props.add_property('huntingSkill', GrapeSwagger::OpenAPI::Schema.new(type: 'string'))
          end
        ]
      end
    end

    before do
      spec.components.add_schema('Pet', pet_schema)
      spec.components.add_schema('Cat', cat_schema)
    end

    subject { GrapeSwagger::Exporter::OAS30.new(spec).export }

    it 'exports discriminator property on base schema' do
      expect(subject[:components][:schemas]['Pet'][:discriminator]).to eq('type')
    end

    it 'exports allOf for child schema' do
      cat = subject[:components][:schemas]['Cat']
      expect(cat[:allOf]).to be_an(Array)
      expect(cat[:allOf].length).to eq(2)
    end

    it 'references parent in allOf using OAS3 path' do
      cat = subject[:components][:schemas]['Cat']
      refs = cat[:allOf].select { |item| item['$ref'] }
      expect(refs.first['$ref']).to eq('#/components/schemas/Pet')
    end

    it 'includes child properties in allOf' do
      cat = subject[:components][:schemas]['Cat']
      props = cat[:allOf].find { |item| item[:properties] }
      expect(props[:properties]).to have_key('huntingSkill')
    end
  end

  describe 'OAS3 discriminator object format' do
    let(:spec) do
      GrapeSwagger::OpenAPI::Document.new.tap do |s|
        s.info = GrapeSwagger::OpenAPI::Info.new(title: 'Test', version: '1.0')
      end
    end

    let(:pet_schema_with_mapping) do
      GrapeSwagger::OpenAPI::Schema.new.tap do |s|
        s.type = 'object'
        # OAS3 discriminator object format
        s.discriminator = {
          propertyName: 'petType',
          mapping: {
            'cat' => '#/components/schemas/Cat',
            'dog' => '#/components/schemas/Dog'
          }
        }
        s.add_property('petType', GrapeSwagger::OpenAPI::Schema.new(type: 'string'))
      end
    end

    before do
      spec.components.add_schema('Pet', pet_schema_with_mapping)
    end

    subject { GrapeSwagger::Exporter::OAS30.new(spec).export }

    it 'preserves discriminator object with propertyName and mapping' do
      discriminator = subject[:components][:schemas]['Pet'][:discriminator]

      expect(discriminator).to be_a(Hash)
      expect(discriminator[:propertyName]).to eq('petType')
      expect(discriminator[:mapping]).to eq({
        'cat' => '#/components/schemas/Cat',
        'dog' => '#/components/schemas/Dog'
      })
    end
  end
end
