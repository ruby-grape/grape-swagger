# frozen_string_literal: true

require 'spec_helper'

describe 'OAS 3.x exporters' do
  let(:document) { GrapeSwagger::OpenAPI::Document.new }
  let(:schema_class) { GrapeSwagger::OpenAPI::Schema }
  let(:export) { GrapeSwagger::Exporter::OAS30.new(document).export }

  describe 'component schemas' do
    it 'exports a named component with only enum and additionalProperties as its own body' do
      document.components.add_schema('Status', schema_class.new(canonical_name: 'Status', enum: %w[a b]))
      document.components.add_schema('Bag', schema_class.new(canonical_name: 'Bag', additional_properties: true))

      expect(export[:components][:schemas]).to eq(
        'Status' => { enum: %w[a b] },
        'Bag' => { additionalProperties: true }
      )
    end

    it 'keeps an alias to another component as a $ref' do
      document.components.add_schema('Pet', schema_class.new(type: 'object'))
      document.components.add_schema('Animal', schema_class.new(canonical_name: 'Pet'))

      expect(export[:components][:schemas]['Animal']).to eq('$ref' => '#/components/schemas/Pet')
    end
  end

  describe 'security schemes' do
    def scheme(attrs)
      document.components.add_security_scheme('s', GrapeSwagger::OpenAPI::SecurityScheme.new(attrs))
      export[:components][:securitySchemes]['s']
    end

    it 'exports http scheme and bearerFormat' do
      expect(scheme(type: 'http', scheme: 'bearer', bearer_format: 'JWT')).to eq(
        type: 'http', scheme: 'bearer', bearerFormat: 'JWT'
      )
    end

    it 'exports the openIdConnect url' do
      expect(scheme(type: 'openIdConnect', open_id_connect_url: 'https://e.test/.well-known')).to eq(
        type: 'openIdConnect', openIdConnectUrl: 'https://e.test/.well-known'
      )
    end

    it 'keeps empty OAuth2 scopes' do
      flows = { 'implicit' => { authorizationUrl: 'https://e.test/auth', scopes: {} } }

      expect(scheme(type: 'oauth2', flows: flows)[:flows]).to eq(flows)
    end
  end

  describe 'empty value handling' do
    let(:exporter) { GrapeSwagger::Exporter::OAS30.new(document) }

    it 'keeps empty hashes under scopes and default but drops nil defaults' do
      result = exporter.send(:compact_hash, { default: nil, other: {}, nested: { scopes: {}, default: {} } })

      expect(result).to eq(nested: { scopes: {}, default: {} })
    end
  end

  describe 'parameter collection formats' do
    def exported_parameter(format, location)
      param = GrapeSwagger::OpenAPI::Parameter.new(
        name: 'ids', location: location, collection_format: format,
        schema: schema_class.new(type: 'array', items: schema_class.new(type: 'string'))
      )
      operation = GrapeSwagger::OpenAPI::Operation.new
      operation.add_parameter(param)
      operation.add_response('200', GrapeSwagger::OpenAPI::Response.new(description: 'ok'))
      path_item = GrapeSwagger::OpenAPI::PathItem.new
      path_item.add_operation(:get, operation)
      document.paths['/x'] = path_item
      export[:paths]['/x'][:get][:parameters].first
    end

    {
      %w[csv query] => { style: 'form', explode: false },
      %w[ssv query] => { style: 'spaceDelimited', explode: false },
      %w[pipes query] => { style: 'pipeDelimited', explode: false },
      %w[multi query] => { style: 'form', explode: true },
      %w[csv path] => { style: 'simple', explode: false },
      %w[csv header] => { style: 'simple', explode: false }
    }.each do |(format, location), expected|
      it "maps #{format} in #{location}" do
        expect(exported_parameter(format, location)).to include(expected)
      end
    end

    it 'omits style for tsv, which OAS 3 cannot express' do
      expect(exported_parameter('tsv', 'query')).not_to include(:style, :explode)
    end
  end
end
