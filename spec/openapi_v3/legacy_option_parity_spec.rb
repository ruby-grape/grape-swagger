# frozen_string_literal: true

require 'spec_helper'

# Options that exist only in grape-swagger (not in grape-oas) must produce the same decisions
# in the OpenAPI 3.x output as they do in Swagger 2.0.
describe 'Swagger 2.0 / OpenAPI 3.x option parity' do
  module OptionParity
    class Item < Grape::Entity
      expose :id, documentation: { type: Integer }
      expose :label, documentation: { type: String }
    end

    class FailError < Grape::Entity
      expose :code, documentation: { type: Integer }
    end
  end

  # rubocop:disable-next Metrics/AbcSize
  def self.api(version, **options)
    Class.new(Grape::API) do
      format :json

      helpers do
        def resource_owner
          'owner-1'
        end
      end

      desc 'One', success: OptionParity::Item
      get('/one') { {} }

      desc 'Many', success: OptionParity::Item, is_array: true
      get('/many') { [] }

      route_setting :swagger, root: true
      desc 'Forced root', success: OptionParity::Item
      get('/forced_root') { {} }

      route_setting :swagger, root: 'custom'
      desc 'Custom root', success: OptionParity::Item
      get('/custom_root') { {} }

      route_setting :swagger, root: false
      desc 'No root', success: OptionParity::Item
      get('/no_root') { {} }

      desc 'Failure', success: OptionParity::Item, failure: [[404, 'Missing', OptionParity::FailError]]
      get('/failing') { {} }

      desc 'Array params', consumes: ['application/x-www-form-urlencoded']
      params do
        requires :group, type: Array do
          requires :a, type: String
          optional :b, type: Integer
        end
        optional :plain, type: [String]
      end
      post('/array_form') { {} }

      desc 'Array body'
      params do
        requires :names, type: [String], documentation: { param_type: 'body' }
      end
      post('/array_body') { {} }

      params { optional :ids, type: Array[Integer] }
      get('/ids_query') { {} }

      desc 'Flat array form', consumes: ['application/x-www-form-urlencoded']
      params do
        optional :ids, type: Array[Integer]
        optional :label, type: String
      end
      post('/ids_form') { {} }

      route_setting :swagger, hidden: ->(owner = nil) { owner == 'owner-1' }
      desc 'Hidden for this owner'
      get('/hidden_by_owner') { {} }

      route_setting :swagger, hidden: ->(owner = nil) { owner != 'owner-1' }
      desc 'Visible for this owner'
      get('/visible_to_owner') { {} }

      desc 'Param hidden by owner', consumes: ['application/x-www-form-urlencoded']
      params do
        optional :keep, type: String
        optional :drop, type: String, documentation: { hidden: ->(owner = nil) { owner == 'owner-1' } }
        optional :shown, type: String, documentation: { hidden: ->(owner = nil) { owner != 'owner-1' } }
      end
      post('/params_by_owner') { {} }

      route_setting :x_path, some: 'stuff'
      route_setting :x_operation, other: 'thing'
      desc 'Extended'
      get('/extended') { {} }

      add_swagger_documentation(version ? { openapi_version: version, **options } : options)
    end
  end

  def generate(version, options)
    klass = self.class.api(version, **options)
    JSON.parse(Rack::MockRequest.new(klass).get('/swagger_doc').body)
  end

  # Rewrites 2.0 reference targets to their 3.x location so the schemas can be compared directly.
  def normalize(object)
    JSON.parse(JSON.generate(object).gsub('#/definitions/', '#/components/schemas/'))
  end

  def response_schema(doc, path, code = '200')
    response = doc.dig('paths', path, 'get', 'responses', code)
    response['schema'] || response['content']&.values&.dig(0, 'schema')
  end

  def resolve(doc, schema)
    return schema unless schema&.key?('$ref')

    name = schema['$ref'].split('/').last
    doc.dig('components', 'schemas', name) || doc.dig('definitions', name)
  end

  # Top-level parameter and body property names; bracketed 2.0 form names collapse to their base name,
  # as 3.x nests them in the schema.
  def param_names(doc, path, verb)
    op = doc.dig('paths', path, verb)
    names = (op['parameters'] || []).filter_map do |p|
      p['in'] == 'body' ? resolve(doc, p['schema'])&.dig('properties')&.keys : p['name'].sub(/\[.*\z/, '')
    end.flatten
    media = op.dig('requestBody', 'content')&.values&.first
    names += resolve(doc, media&.dig('schema'))&.dig('properties')&.keys || []
    names.uniq.sort
  end

  # Names exactly as emitted: parameter names plus form body properties, braces and duplicates kept.
  def raw_names(doc, path, verb)
    op = doc.dig('paths', path, verb)
    names = (op['parameters'] || []).map { |p| p['name'] }
    media = op.dig('requestBody', 'content')&.values&.first
    names + (resolve(doc, media&.dig('schema'))&.dig('properties')&.keys || [])
  end

  def self.each_version(**options, &)
    %w[3.0 3.1].each do |version|
      context "with openapi_version #{version}" do
        let(:version) { version }
        let(:legacy) { generate(nil, options) }
        let(:oas) { generate(version, options) }

        class_exec(&)
      end
    end
  end

  describe 'add_root: true' do
    each_version(add_root: true) do
      it 'wraps single, array and customised roots like 2.0 does' do
        %w[/one /many /forced_root /custom_root /no_root /failing].each do |path|
          expected = normalize(response_schema(legacy, path))
          expect(response_schema(oas, path)).to eq(expected), path
        end
        expect(response_schema(oas, '/one')).to eq(
          'type' => 'object',
          'properties' => { 'option_parity_item' => { '$ref' => '#/components/schemas/OptionParity_Item' } }
        )
        expect(response_schema(oas, '/many').dig('properties', 'option_parity_items')).to include('type' => 'array')
        expect(response_schema(oas, '/custom_root')['properties'].keys).to eq(['custom'])
        expect(response_schema(oas, '/no_root')).to eq('$ref' => '#/components/schemas/OptionParity_Item')
      end

      it 'wraps error responses the same way' do
        expect(response_schema(oas, '/failing', '404')).to eq(normalize(response_schema(legacy, '/failing', '404')))
      end

      it 'is a valid document' do
        expect(oas).to be_valid_openapi(version)
      end
    end
  end

  describe 'add_root: false' do
    each_version do
      it 'only wraps routes that ask for a root' do
        %w[/one /many /forced_root /custom_root /no_root].each do |path|
          expect(response_schema(oas, path)).to eq(normalize(response_schema(legacy, path))), path
        end
        expect(response_schema(oas, '/one')).to eq('$ref' => '#/components/schemas/OptionParity_Item')
      end
    end
  end

  describe 'array_use_braces' do
    [true, false].each do |braces|
      context "set to #{braces}" do
        each_version(array_use_braces: braces) do
          it 'names array parameters like 2.0 does' do
            ids_name = braces ? 'ids[]' : 'ids'
            %w[/array_form /array_body].each do |path|
              expect(param_names(oas, path, 'post')).to eq(param_names(legacy, path, 'post')), path
            end
            expect(raw_names(oas, '/ids_query', 'get')).to eq([ids_name])
            expect(raw_names(oas, '/ids_query', 'get')).to eq(raw_names(legacy, '/ids_query', 'get'))
            expect(raw_names(oas, '/ids_form', 'post').sort).to eq(raw_names(legacy, '/ids_form', 'post').sort)
            expect(raw_names(oas, '/ids_form', 'post').sort).to eq([ids_name, 'label'])
            form = oas.dig('components', 'schemas', 'postArrayForm')
            expect(form['properties'].keys).to eq(%w[group plain])
            expect(form.dig('properties', 'group', 'items', 'properties').keys).to eq(%w[a b])
          end

          it 'is a valid document' do
            expect(oas).to be_valid_openapi(version)
          end
        end
      end
    end
  end

  describe 'token_owner' do
    each_version(token_owner: 'resource_owner') do
      it 'hides and shows routes by owner like 2.0 does' do
        legacy_paths = legacy['paths'].keys
        expect(oas['paths'].keys).to eq(legacy_paths)
        expect(oas['paths'].keys).to include('/visible_to_owner')
        expect(oas['paths'].keys).not_to include('/hidden_by_owner')
      end

      it 'hides and shows parameters by owner like 2.0 does' do
        names = param_names(oas, '/params_by_owner', 'post')
        expect(names).to eq(param_names(legacy, '/params_by_owner', 'post'))
        expect(names).to include('keep')
      end

      it 'passes the token owner to parameter-level hidden procs' do
        pending 'RouteRules.hidden_parameter? evaluates parameter procs without the owner (2.0 behaves the same)'
        names = param_names(oas, '/params_by_owner', 'post')
        expect(names).to include('keep', 'shown')
        expect(names).not_to include('drop')
      end

      it 'is a valid document' do
        expect(oas).to be_valid_openapi(version)
      end
    end

    context 'without token_owner configured' do
      each_version do
        it 'evaluates owner procs with no owner, like 2.0' do
          expect(oas['paths'].keys).to eq(legacy['paths'].keys)
        end
      end
    end
  end

  describe 'x_path and x_operation' do
    each_version do
      it 'copies the extensions like 2.0 does' do
        legacy_item = legacy.dig('paths', '/extended')
        item = oas.dig('paths', '/extended')
        expect(item['x-some']).to eq(legacy_item['x-some'])
        expect(item['x-some']).to eq('stuff')
        expect(item.dig('get', 'x-other')).to eq(legacy_item.dig('get', 'x-other'))
        expect(item.dig('get', 'x-other')).to eq('thing')
      end
    end
  end
end
