# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI do
  describe GrapeSwagger::OpenAPI::Schema do
    it 'does not duplicate required names' do
      schema = described_class.new
      2.times { schema.mark_required(:id) }

      expect(schema.required).to eq ['id']
    end
  end

  describe GrapeSwagger::OpenAPI::Parameter do
    it 'is always required when located in the path' do
      expect(described_class.new(name: 'id', location: 'path', required: false).required).to be true
    end

    it 'follows the declared requiredness elsewhere' do
      expect(described_class.new(name: 'q', location: 'query', required: false).required).to be false
    end
  end

  describe GrapeSwagger::OpenAPI::Parameter do
    def style_for(format, location)
      param = described_class.new(name: 'ids', location: location, collection_format: format)
      [param.style_from_collection_format, param.explode_from_collection_format]
    end

    it 'maps query collection formats to style and explode' do
      expect(style_for('csv', 'query')).to eq ['form', false]
      expect(style_for('ssv', 'query')).to eq ['spaceDelimited', false]
      expect(style_for('pipes', 'query')).to eq ['pipeDelimited', false]
      expect(style_for('multi', 'query')).to eq ['form', true]
    end

    it 'maps csv in path and header to simple' do
      expect(style_for('csv', 'path')).to eq ['simple', false]
      expect(style_for('csv', 'header')).to eq ['simple', false]
    end

    it 'has no mapping for tsv, brackets or an unset format' do
      expect(style_for('tsv', 'query')).to eq [nil, nil]
      expect(style_for('brackets', 'query')).to eq [nil, nil]
      expect(style_for(nil, 'query')).to eq [nil, nil]
    end
  end

  describe GrapeSwagger::OpenAPI::Server do
    it 'builds a url from Swagger 2.0 host, scheme and base path' do
      server = described_class.from_swagger2(host: 'api.example.com', base_path: '/v1', scheme: 'http')

      expect(server.url).to eq 'http://api.example.com/v1'
    end

    it 'ignores a root base path' do
      expect(described_class.from_swagger2(host: 'example.com', base_path: '/').url).to eq 'https://example.com'
    end
  end

  describe GrapeSwagger::OpenAPI::Info do
    it 'exposes contact and license only when something is set' do
      expect(described_class.new.contact).to be_nil
      expect(described_class.new.license).to be_nil
    end

    it 'compacts contact and license hashes' do
      info = described_class.new(contact_name: 'Ann', license_name: 'MIT', license_identifier: 'MIT')

      expect(info.contact).to eq(name: 'Ann')
      expect(info.license).to eq(name: 'MIT', identifier: 'MIT')
    end
  end

  describe GrapeSwagger::OpenAPI::Document do
    it 'ignores a tag whose name is already present' do
      document = described_class.new
      document.add_tag(GrapeSwagger::OpenAPI::Tag.new(name: 'pets'))
      document.add_tag(GrapeSwagger::OpenAPI::Tag.new(name: 'pets', description: 'again'))

      expect(document.tags.map(&:name)).to eq ['pets']
    end

    it 'registers component schemas by name' do
      document = described_class.new
      schema = GrapeSwagger::OpenAPI::Schema.new(type: 'object')
      document.components.add_schema('Pet', schema)

      expect(document.components.schemas).to eq('Pet' => schema)
    end
  end
end
