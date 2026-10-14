# frozen_string_literal: true

require 'spec_helper'

describe 'OAS 3.x exporters: nullable references and composition' do
  let(:schema_class) { GrapeSwagger::OpenAPI::Schema }
  let(:foo_ref) { { '$ref' => '#/components/schemas/Foo' } }
  let(:null30) { { type: 'object', nullable: true, enum: [nil] } }
  let(:null31) { { type: 'null' } }

  def export(exporter_class, schema)
    spec = GrapeSwagger::OpenAPI::Document.new
    spec.components.add_schema('Foo', schema_class.new(type: 'object'))
    spec.components.add_schema('T', schema)
    exporter_class.new(spec).export[:components][:schemas]['T']
  end

  def export30(schema) = export(GrapeSwagger::Exporter::OAS30, schema)
  def export31(schema) = export(GrapeSwagger::Exporter::OAS31, schema)

  describe 'nullable $ref' do
    let(:schema) { schema_class.new(canonical_name: 'Foo', nullable: true) }

    it 'OAS 3.0 offers a null alternative next to the bare $ref' do
      expect(export30(schema)).to eq(anyOf: [foo_ref, null30])
    end

    it 'OAS 3.1 offers a type null alternative next to the bare $ref' do
      expect(export31(schema)).to eq(anyOf: [foo_ref, null31])
    end

    it 'keeps the description beside the union' do
      schema.description = 'the foo'

      expect(export30(schema)).to eq(description: 'the foo', anyOf: [foo_ref, null30])
      expect(export31(schema)).to eq(description: 'the foo', anyOf: [foo_ref, null31])
    end

    it 'applies to object properties' do
      parent = schema_class.new(type: 'object', properties: { 'foo' => schema })

      expect(export30(parent)[:properties]['foo']).to eq(anyOf: [foo_ref, null30])
      expect(export31(parent)[:properties]['foo']).to eq(anyOf: [foo_ref, null31])
    end
  end

  describe '$ref siblings' do
    it 'leaves a plain $ref bare' do
      schema = schema_class.new(canonical_name: 'Foo')

      expect(export30(schema)).to eq(foo_ref)
      expect(export31(schema)).to eq(foo_ref)
    end

    it 'wraps the $ref in allOf when a description is present' do
      schema = schema_class.new(canonical_name: 'Foo', description: 'the foo')
      wrapped = { description: 'the foo', allOf: [foo_ref] }

      expect(export30(schema)).to eq(wrapped)
      expect(export31(schema)).to eq(wrapped)
    end

    it 'does not turn a component definition that has a canonical name into a self reference' do
      schema = schema_class.new(
        canonical_name: 'T',
        all_of: [schema_class.new(canonical_name: 'Foo'), schema_class.new(type: 'object')]
      )

      expect(export30(schema)[:allOf].first).to eq(foo_ref)
      expect(export31(schema)).not_to have_key('$ref')
    end
  end

  describe 'nullable arrays' do
    let(:schema) { schema_class.new(type: 'array', nullable: true, items: schema_class.new(canonical_name: 'Foo')) }

    it 'marks the array nullable and keeps a bare item $ref' do
      expect(export30(schema)).to eq(type: 'array', nullable: true, items: foo_ref)
      expect(export31(schema)).to eq(type: %w[array null], items: foo_ref)
    end
  end

  describe 'nullable composition' do
    let(:schema) do
      schema_class.new(
        nullable: true,
        one_of: [schema_class.new(canonical_name: 'Foo'), schema_class.new(type: 'string')],
        discriminator: { property_name: 'kind' }
      )
    end
    let(:branch) { { oneOf: [foo_ref, { type: 'string' }], discriminator: { propertyName: 'kind' } } }

    it 'OAS 3.0 allows null alongside the composition' do
      expect(export30(schema)).to eq(anyOf: [branch, null30])
    end

    it 'OAS 3.1 allows null alongside the composition' do
      expect(export31(schema)).to eq(anyOf: [branch, null31])
    end

    it 'leaves a non-nullable composition untouched' do
      schema.nullable = nil

      expect(export30(schema)).to eq(branch)
    end
  end

  describe 'nullable composition with several keywords' do
    let(:schema) do
      schema_class.new(
        nullable: true,
        all_of: [schema_class.new(canonical_name: 'Foo')],
        any_of: [schema_class.new(type: 'string')]
      )
    end
    let(:branch) { { allOf: [foo_ref], anyOf: [{ type: 'string' }] } }

    it 'keeps every keyword inside the non-null alternative' do
      expect(export30(schema)).to eq(anyOf: [branch, null30])
      expect(export31(schema)).to eq(anyOf: [branch, null31])
    end
  end

  describe 'inline parameter enums' do
    it 'drops null members' do
      param = GrapeSwagger::OpenAPI::Parameter.new(name: 'q', location: 'query', type: 'string', enum: [nil, 'a'])
      op = GrapeSwagger::OpenAPI::Operation.new
      op.parameters << param
      item = GrapeSwagger::OpenAPI::PathItem.new
      item.add_operation('get', op)
      spec = GrapeSwagger::OpenAPI::Document.new
      spec.paths['/x'] = item

      out = GrapeSwagger::Exporter::OAS30.new(spec).export
      expect(out[:paths]['/x'][:get][:parameters].first[:schema][:enum]).to eq(['a'])
    end
  end

  describe 'nullable enums' do
    it 'keeps null among the members of a nullable enum' do
      schema = schema_class.new(type: 'string', nullable: true, enum: ['a', nil])

      expect(export30(schema)).to eq(type: 'string', nullable: true, enum: ['a', nil])
      expect(export31(schema)).to eq(type: %w[string null], enum: ['a', nil])
    end

    it 'drops null members from a non-nullable enum' do
      schema = schema_class.new(type: 'string', enum: ['a', nil])

      expect(export30(schema)).to eq(type: 'string', enum: ['a'])
      expect(export31(schema)).to eq(type: 'string', enum: ['a'])
    end

    it 'admits null in a nullable enum that lacks the member' do
      schema = schema_class.new(type: 'string', nullable: true, enum: %w[a b])

      expect(export30(schema)[:enum]).to eq(['a', 'b', nil])
      expect(export31(schema)[:enum]).to eq(['a', 'b', nil])
    end

    it 'keeps a boolean enum of only false' do
      schema = schema_class.new(type: 'boolean', enum: [false])

      expect(export30(schema)).to eq(type: 'boolean', enum: [false])
    end
  end

  describe 'discriminator' do
    def discriminator(value)
      schema = schema_class.new(type: 'object', discriminator: value)
      export30(schema)[:discriminator]
    end

    it 'normalizes the model hash to propertyName and mapping' do
      mapping = { 'foo' => '#/components/schemas/Foo' }

      expect(discriminator(property_name: 'kind', mapping: mapping)).to eq(propertyName: 'kind', mapping: mapping)
      expect(discriminator('propertyName' => 'kind', 'mapping' => {})).to eq(propertyName: 'kind')
    end

    it 'turns the Swagger 2.0 property name into an object' do
      expect(discriminator('kind')).to eq(propertyName: 'kind')
      expect(discriminator(:kind)).to eq(propertyName: 'kind')
    end
  end

  describe 'through a route' do
    def schema_for(version)
      api = Class.new(Grape::API) do
        format :json

        params do
          optional :status, type: String, values: %w[a b], documentation: { nullable: true }
          optional :flag, type: Grape::API::Boolean, values: [false]
        end
        post '/items' do
          {}
        end

        add_swagger_documentation(openapi_version: version)
      end

      session = Rack::Test::Session.new(Rack::MockSession.new(api))
      session.get '/swagger_doc'
      JSON.parse(session.last_response.body)['components']['schemas']['postItems']['properties']
    end

    it 'emits nullable and boolean enums for OAS 3.0' do
      props = schema_for('3.0')

      expect(props['status']).to include('nullable' => true, 'enum' => ['a', 'b', nil])
      expect(props['flag']['enum']).to eq([false])
    end

    it 'emits nullable and boolean enums for OAS 3.1' do
      props = schema_for('3.1')

      expect(props['status']).to include('type' => %w[string null], 'enum' => ['a', 'b', nil])
      expect(props['flag']['enum']).to eq([false])
    end
  end
end
