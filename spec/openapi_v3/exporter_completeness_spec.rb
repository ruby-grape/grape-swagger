# frozen_string_literal: true

require 'spec_helper'

describe 'OAS 3.x exporters: completeness' do
  let(:oas) { GrapeSwagger::OpenAPI }
  let(:document) { oas::Document.new }

  def export(version) = GrapeSwagger::Exporter.export(document, version: version)

  def export_schema(version, schema)
    document.components.add_schema('T', schema)
    export(version)[:components][:schemas]['T']
  end

  def export_operation(version, operation)
    document.add_path('/x', oas::PathItem.new.tap { |p| p.add_operation('get', operation) })
    export(version)[:paths]['/x'][:get]
  end

  describe 'document level' do
    it 'always writes paths for OAS 3.0' do
      expect(export('3.0')[:paths]).to eq({})
    end

    it 'always writes paths for OAS 3.1, as the root needs paths, components or webhooks' do
      expect(export('3.1')[:paths]).to eq({})
    end

    %w[3.0 3.1].each do |version|
      it "exports reusable components for #{version}" do
        c = document.components
        c.responses['Gone'] = oas::Response.new(description: 'gone')
        c.parameters['Page'] = oas::Parameter.new(name: 'page', location: 'query', type: 'integer')
        c.request_bodies['Body'] = oas::RequestBody.new(description: 'b')
        c.headers['Rate'] = oas::Header.new(description: 'r', type: 'integer')
        c.examples['Ex'] = { value: 1 }
        c.responses['Alias'] = { '$ref' => '#/components/responses/Gone' }
        c.extensions['x-c'] = 1

        out = export(version)[:components]
        expect(out[:responses]['Gone']).to eq(description: 'gone')
        expect(out[:responses]['Alias']).to eq('$ref' => '#/components/responses/Gone')
        expect(out[:parameters]['Page'][:schema]).to eq(type: 'integer')
        expect(out[:requestBodies]['Body']).to eq(description: 'b')
        expect(out[:headers]['Rate'][:schema]).to eq(type: 'integer')
        expect(out[:examples]['Ex']).to eq(value: 1)
        expect(out['x-c']).to eq(1)
      end

      it "keeps components that hold only a reusable response for #{version}" do
        document.components.responses['Gone'] = oas::Response.new(description: 'gone')

        expect(export(version)[:components]).to eq(responses: { 'Gone' => { description: 'gone' } })
      end

      it "exports a Schema additionalProperties for #{version}" do
        schema = oas::Schema.new(type: 'object', additional_properties: oas::Schema.new(type: 'string'))

        expect(export_schema(version, schema)[:additionalProperties]).to eq(type: 'string')
      end

      it "exports root externalDocs for #{version}" do
        document.external_docs = { url: 'https://example.com/docs', description: 'More' }

        expect(export(version)[:externalDocs]).to eq(url: 'https://example.com/docs', description: 'More')
      end

      it "exports operation externalDocs and servers for #{version}" do
        operation = oas::Operation.new(
          external_docs: { url: 'https://example.com/op' },
          servers: [oas::Server.new(url: 'https://op.example.com', description: 'op')]
        )

        result = export_operation(version, operation)
        expect(result[:externalDocs]).to eq(url: 'https://example.com/op')
        expect(result[:servers]).to eq([{ url: 'https://op.example.com', description: 'op' }])
      end
    end
  end

  describe 'schema keywords' do
    let(:bounded) do
      oas::Schema.new(type: 'integer', minimum: 1, maximum: 9, exclusive_minimum: true, exclusive_maximum: true)
    end

    it 'writes numeric exclusive bounds for OAS 3.1' do
      expect(export_schema('3.1', bounded)).to eq(type: 'integer', exclusiveMinimum: 1, exclusiveMaximum: 9)
    end

    it 'keeps the boolean form with minimum and maximum for OAS 3.0' do
      expect(export_schema('3.0', bounded)).to eq(
        type: 'integer', minimum: 1, maximum: 9, exclusiveMinimum: true, exclusiveMaximum: true
      )
    end

    it 'coerces a numeric exclusive bound to the boolean form for OAS 3.0' do
      schema = oas::Schema.new(type: 'integer', exclusive_minimum: 5)

      expect(export_schema('3.0', schema)).to eq(type: 'integer', minimum: 5, exclusiveMinimum: true)
    end

    it 'keeps a numeric exclusive bound for OAS 3.1' do
      schema = oas::Schema.new(type: 'integer', exclusive_maximum: 5)

      expect(export_schema('3.1', schema)).to eq(type: 'integer', exclusiveMaximum: 5)
    end

    it 'keeps a numeric exclusive bound next to a plain bound for OAS 3.1' do
      schema = oas::Schema.new(type: 'integer', minimum: 1, maximum: 9, exclusive_minimum: 3, exclusive_maximum: 7)

      expect(export_schema('3.1', schema)).to eq(
        type: 'integer', minimum: 1, exclusiveMinimum: 3, maximum: 9, exclusiveMaximum: 7
      )
    end

    it 'keeps the tighter bound when both a numeric exclusive and a plain bound are set for OAS 3.0' do
      tighter = oas::Schema.new(type: 'integer', minimum: 1, maximum: 9, exclusive_minimum: 3, exclusive_maximum: 7)
      looser = oas::Schema.new(type: 'integer', minimum: 5, maximum: 6, exclusive_minimum: 3, exclusive_maximum: 7)

      expect(export_schema('3.0', tighter)).to eq(
        type: 'integer', minimum: 3, exclusiveMinimum: true, maximum: 7, exclusiveMaximum: true
      )
      document.components.schemas.clear
      expect(export_schema('3.0', looser)).to eq(type: 'integer', minimum: 5, maximum: 6)
    end

    it 'does not write exclusive flags without a bound for OAS 3.0' do
      schema = oas::Schema.new(type: 'integer', exclusive_minimum: true, exclusive_maximum: true)

      expect(export_schema('3.0', schema)).to eq(type: 'integer')
    end

    it 'does not duplicate null in the type of a nullable null schema for OAS 3.1' do
      expect(export_schema('3.1', oas::Schema.new(type: 'null', nullable: true))).to eq(type: 'null')
    end

    it 'falls back to the first of examples as the example for OAS 3.0' do
      schema = oas::Schema.new(type: 'string', examples: %w[a b])

      expect(export_schema('3.0', schema)).to eq(type: 'string', example: 'a')
    end

    it 'compacts nil fields in OAS 3.0 paths' do
      param = oas::Parameter.new(name: 'q', location: 'query', type: 'string', required: nil,
                                 extensions: { 'x-n' => nil })
      document.add_path('/x', oas::PathItem.new.tap do |p|
        p.add_operation('get', oas::Operation.new(parameters: [param]))
      end)

      exported = export('3.0')[:paths]['/x'][:get][:parameters].first

      expect(exported).not_to have_key(:required)
      expect(exported).not_to have_key('x-n')
    end

    it 'writes the examples keyword for OAS 3.1 only' do
      schema = oas::Schema.new(type: 'string', examples: %w[a b])

      expect(export_schema('3.1', schema)).to eq(type: 'string', examples: %w[a b])
      expect(export_schema('3.0', schema)).not_to have_key(:examples)
    end

    it 'exports a null typed schema as a typed null for OAS 3.0' do
      expect(export_schema('3.0', oas::Schema.new(type: 'null'))).to eq(type: 'object', nullable: true, enum: [nil])
      expect(export_schema('3.1', oas::Schema.new(type: 'null'))).to eq(type: 'null')
    end

    it 'keeps a nil-only enum on a nullable schema' do
      schema = oas::Schema.new(type: 'string', nullable: true, enum: [nil])

      expect(export_schema('3.0', schema)).to eq(type: 'string', nullable: true, enum: [nil])
      expect(export_schema('3.1', schema)).to eq(type: %w[string null], enum: [nil])
    end
  end

  describe 'parameters and headers' do
    def parameter(version, attrs)
      export_operation(version, oas::Operation.new(parameters: [oas::Parameter.new({ name: 'p', location: 'query' }.merge(attrs))])).then do |op|
        op[:parameters].first
      end
    end

    it 'emits explode without style' do
      expect(parameter('3.0', explode: false)).to include(explode: false)
      expect(parameter('3.0', explode: false)).not_to have_key(:style)
    end

    it 'emits allowReserved' do
      expect(parameter('3.1', allow_reserved: true)).to include(allowReserved: true)
    end

    it 'exports header type, format, items, style, explode, example and examples' do
      header = oas::Header.new(
        type: 'array', items: oas::Schema.new(type: 'string'), style: 'simple', explode: false,
        example: %w[a], examples: { one: { value: %w[b] } }
      )
      document.add_path('/x', oas::PathItem.new.tap do |p|
        p.add_operation('get', oas::Operation.new(responses: { '200' => oas::Response.new(description: 'ok', headers: { 'X-List' => header }) }))
      end)

      exported = export('3.0')[:paths]['/x'][:get][:responses]['200'][:headers]['X-List']
      expect(exported).to eq(
        schema: { type: 'array', items: { type: 'string' } },
        style: 'simple', explode: false, example: %w[a], examples: { one: { value: %w[b] } }
      )
    end
  end
end
