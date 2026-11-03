# frozen_string_literal: true

require 'spec_helper'

# Every generated OpenAPI 3.x document must validate against the official meta-schema.
describe 'OpenAPI 3.x output validity' do
  module SchemaValidity
    class Base < Grape::Entity
      expose :kind, documentation: { type: String, is_discriminator: true, required: true }
      expose :id, documentation: { type: Integer }
    end

    class Cat < Base
      expose :lives, documentation: { type: Integer }
    end

    class Address < Grape::Entity
      expose :street, documentation: { type: String, desc: 'Street', x: { nullable: true } }
    end

    class Person < Grape::Entity
      expose :name, documentation: { type: String, required: true, example: 'Ann' }
      expose :nick, documentation: { type: String, x: { nullable: true } }
      expose :tags, documentation: { type: String, is_array: true }
      expose :address, using: Address, documentation: { type: Address, desc: 'Home' }
      expose :addresses, using: Address, documentation: { type: Address, is_array: true }
    end
  end

  def self.api(version, **, &)
    Class.new(Grape::API).tap do |api|
      api.format :json
      api.class_eval(&)
      api.add_swagger_documentation(openapi_version: version, **)
    end
  end

  def doc_of(klass)
    @app = klass
    get '/swagger_doc'
    JSON.parse(last_response.body).tap { |doc| expect(doc['paths']).not_to be_empty }
  end

  attr_reader :app

  %w[3.0 3.1].each do |version|
    context "with #{version}" do
      it 'validates params in every location, with every collection format' do
        klass = self.class.api(version) do
          desc 'Everything'
          params do
            requires :id, type: Integer, documentation: { param_type: 'path' }
            requires :token, type: String, documentation: { param_type: 'header' }
            optional :q, type: String, values: %w[a b], default: 'a'
            optional :ids, type: [Integer], documentation: { collectionFormat: 'csv' }
            optional :pipes, type: [String], documentation: { collectionFormat: 'pipes' }
            optional :multi, type: [String], documentation: { collectionFormat: 'multi' }
            optional :ssv, type: [String], documentation: { collectionFormat: 'ssv' }
            optional :tsv, type: [String], documentation: { collectionFormat: 'tsv' }
            optional :range, type: Integer, values: 1..10
            optional :flag, type: Grape::API::Boolean
            optional :at, type: DateTime
          end
          get '/things/:id' do
            {}
          end
        end
        expect(doc_of(klass)).to be_valid_openapi(version)
      end

      it 'validates request bodies, forms and file uploads' do
        klass = self.class.api(version) do
          desc 'json body'
          params do
            requires :name, type: String
            optional :nested, type: Hash do
              optional :a, type: Integer
              optional :list, type: Array do
                requires :b, type: String
              end
            end
          end
          post('/json') { {} }

          desc 'form', consumes: ['application/x-www-form-urlencoded']
          params { requires :x, type: String }
          post('/form') { {} }

          desc 'upload', consumes: ['multipart/form-data']
          params do
            requires :file, type: File
            optional :note, type: String
          end
          post('/upload') { {} }

          desc 'download', success: 'file'
          get('/download') { '' }
        end
        expect(doc_of(klass)).to be_valid_openapi(version)
      end

      it 'validates entities: nested, arrays, nullable, inheritance and discriminator' do
        klass = self.class.api(version) do
          desc 'person', success: SchemaValidity::Person
          get('/person') { {} }

          desc 'people', is_array: true, success: SchemaValidity::Person
          get('/people') { [] }

          desc 'cat', success: SchemaValidity::Cat
          get('/cat') { {} }

          desc 'make person', success: { code: 201, model: SchemaValidity::Person }, body_name: 'person'
          params { requires :person, type: Hash }
          post('/person') { {} }
        end
        expect(doc_of(klass)).to be_valid_openapi(version)
      end

      it 'validates every security scheme type' do
        klass = self.class.api(
          version,
          security_definitions: {
            key: { type: 'apiKey', name: 'X-Key', in: 'header' },
            basic: { type: 'basic' },
            oauth: {
              type: 'oauth2', flow: 'accessCode', authorizationUrl: 'https://e.com/a', tokenUrl: 'https://e.com/t',
              scopes: { read: 'Read' }
            },
            oauth_implicit: {
              type: 'oauth2', flow: 'implicit', authorizationUrl: 'https://e.com/a', scopes: { read: 'Read' }
            },
            oauth_password: { type: 'oauth2', flow: 'password', tokenUrl: 'https://e.com/t', scopes: {} },
            oauth_app: { type: 'oauth2', flow: 'application', tokenUrl: 'https://e.com/t', scopes: {} },
            bearer: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
            oidc: { type: 'openIdConnect', openIdConnectUrl: 'https://e.com/.well-known/openid-configuration' }
          },
          security: [{ key: [] }]
        ) do
          desc 'secured', security: [{ oauth: ['read'] }, { bearer: [] }]
          get('/secured') { {} }
        end
        expect(doc_of(klass)).to be_valid_openapi(version)
      end

      it 'validates tags with externalDocs, info, servers and response headers' do
        klass = self.class.api(
          version,
          info: { title: 'T', description: 'D', contact_name: 'C', contact_email: 'c@e.com', license: 'MIT',
                  license_url: 'https://e.com/l', terms_of_service_url: 'https://e.com/tos' },
          tags: [{ name: 'things', description: 'Things', externalDocs: { url: 'https://e.com', description: 'x' } }],
          host: 'api.example.com', base_path: '/v1', schemes: %w[https]
        ) do
          desc 'headers', tags: ['things'],
                          success: { model: SchemaValidity::Address,
                                     headers: { 'X-Rate' => { description: 'Remaining', type: 'integer' } } },
                          failure: [[404, 'Missing', SchemaValidity::Address,
                                     nil, { 'X-Err' => { description: 'Code', type: 'string' } }]]
          get('/h') { {} }

          desc 'deprecated', deprecated: true, produces: ['text/plain'], nickname: 'old'
          get('/old') { '' }
        end
        expect(doc_of(klass)).to be_valid_openapi(version)
      end
    end
  end

  it 'validates 3.1 webhooks and a JSON Schema dialect' do
    klass = self.class.api(
      '3.1',
      json_schema_dialect: 'https://spec.openapis.org/oas/3.1/dialect/base',
      webhooks: {
        newPet: {
          post: {
            summary: 'New pet',
            requestBody: { content: { 'application/json' => { schema: { '$ref' => '#/definitions/Pet' } } } },
            responses: { '200' => { description: 'ok' } }
          }
        }
      }
    ) do
      desc 'x'
      get('/x') { {} }
    end
    expect(doc_of(klass)).to be_valid_openapi('3.1')
  end

  it 'expresses nullable as the keyword in 3.0' do
    doc = doc_of(self.class.api('3.0') { get('/p', desc: 'p', success: SchemaValidity::Person) { {} } })
    expect(doc.dig('components', 'schemas', 'SchemaValidity_Person', 'properties', 'nick')).to include('nullable' => true)
    expect(doc).to be_valid_openapi('3.0')
  end

  it 'expresses nullable as a type union in 3.1' do
    doc = doc_of(self.class.api('3.1') { get('/p', desc: 'p', success: SchemaValidity::Person) { {} } })
    nick = doc.dig('components', 'schemas', 'SchemaValidity_Person', 'properties', 'nick')
    expect(nick).to eq('type' => %w[string null])
    expect(doc).to be_valid_openapi('3.1')
  end

  describe 'composition built through the exporters' do
    def composed_spec
      s_class = GrapeSwagger::OpenAPI::Schema
      spec = GrapeSwagger::OpenAPI::Document.new
      spec.info = GrapeSwagger::OpenAPI::Info.new(title: 'T', version: '1')
      pet = s_class.new(type: 'object').tap do |s|
        s.discriminator = { propertyName: 'type', mapping: { cat: '#/components/schemas/Cat' } }
        s.add_property('type', s_class.new(type: 'string'))
        s.mark_required('type')
      end
      cat = s_class.new.tap do |s|
        s.all_of = [s_class.new(canonical_name: 'Pet'),
                    s_class.new(type: 'object').tap { |o| o.add_property('lives', s_class.new(type: 'integer')) }]
      end
      either = s_class.new.tap { |s| s.one_of = [s_class.new(canonical_name: 'Cat'), s_class.new(type: 'string')] }
      maybe = s_class.new.tap { |s| s.any_of = [s_class.new(canonical_name: 'Cat')] }
      maybe.nullable = true
      { 'Pet' => pet, 'Cat' => cat, 'Either' => either, 'Maybe' => maybe }.each { |n, sc| spec.components.add_schema(n, sc) }
      op = GrapeSwagger::OpenAPI::Operation.new.tap do |o|
        o.operation_id = 'make'
        o.add_response('201', GrapeSwagger::OpenAPI::Response.new.tap do |r|
          r.description = 'ok'
          r.links = { 'Get' => { 'operationId' => 'make', 'parameters' => { 'id' => '$response.body#/id' } } }
        end)
      end
      spec.paths['/x'] = GrapeSwagger::OpenAPI::PathItem.new.tap { |pi| pi.add_operation(:post, op) }
      spec
    end

    it 'is valid 3.0' do
      expect(GrapeSwagger::Exporter::OAS30.new(composed_spec).export).to be_valid_openapi('3.0')
    end

    it 'is valid 3.1' do
      expect(GrapeSwagger::Exporter::OAS31.new(composed_spec).export).to be_valid_openapi('3.1')
    end
  end

  it 'rejects an invalid document (the matcher is not vacuous)' do
    expect({ 'openapi' => '3.0.0', 'info' => {}, 'paths' => {} }).not_to be_valid_openapi('3.0')
    expect({ 'openapi' => '3.1.0', 'info' => { 'title' => 't' }, 'paths' => 1 }).not_to be_valid_openapi('3.1')
  end
end
