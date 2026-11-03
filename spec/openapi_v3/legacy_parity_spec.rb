# frozen_string_literal: true

require 'spec_helper'

# The OAS 3.x builder and the Swagger 2.0 generator share their per-route rules
# (GrapeSwagger::DocMethods::RouteRules); this spec fails when the outputs drift apart.
describe 'Swagger 2.0 / OpenAPI 3.x parity' do
  include_context "#{MODEL_PARSER} swagger example"

  def self.build_api(version)
    Class.new(Grape::API) do
      format :json
      prefix :api
      version 'v1', using: :path

      resource :things do
        desc 'List things', tags: %w[inventory]
        params do
          optional :q, type: String
          optional :secret, type: String, documentation: { hidden: true }
        end
        get { [] }

        desc 'Create', success: { code: 202, message: 'Accepted' }, failure: [[400, 'Bad'], [409, 'Conflict']]
        params do
          requires :name, type: String
          optional :hidden_opt, type: String, documentation: { hidden: -> { true } }
        end
        post { {} }

        desc 'Hidden', hidden: true
        get(:secret) { {} }

        desc 'Hidden proc', hidden: -> { true }
        get(:proc_hidden) { {} }

        desc 'Shown proc', hidden: -> { false }
        get(:proc_shown) { {} }

        desc 'Delete one'
        params { requires :id, type: Integer }
        delete(':id') { {} }

        desc 'Upload', consumes: ['multipart/form-data'], produces: ['application/xml']
        params { requires :file, type: File }
        put(:upload) { {} }

        desc 'Download', success: 'file'
        get(:download) { '' }
      end

      namespace :widgets do
        desc 'Widgets', default_response: { message: 'Oops' }
        get { [] }

        desc 'Explicit tags', tags: %w[custom_tag]
        patch(':id') { {} }
      end

      add_swagger_documentation(
        openapi_version: version,
        tags: [{ name: 'widgets', description: 'User widgets' }, { name: 'extra', description: 'Unused' }]
      )
    end
  end

  def fetch(app_class)
    @app_class = app_class
    get '/api/v1/swagger_doc'
    JSON.parse(last_response.body)
  end

  def app
    @app_class
  end

  def operations(doc)
    doc['paths'].flat_map do |path, item|
      item.slice(*%w[get post put patch delete]).map { |verb, op| [[path, verb], op] }
    end.to_h
  end

  let(:legacy) { fetch(self.class.build_api(nil)) }

  %w[3.0 3.1].each do |version|
    context "with openapi_version #{version}" do
      let(:oas) { fetch(self.class.build_api(version)) }
      let(:legacy_ops) { operations(legacy) }
      let(:oas_ops) { operations(oas) }

      it 'documents the same paths and methods, without hidden routes' do
        expect(oas_ops.keys).to match_array(legacy_ops.keys)
        paths = oas_ops.keys.map(&:first)
        expect(paths).to include('/api/v1/things/proc_shown')
        expect(paths).not_to include('/api/v1/things/secret', '/api/v1/things/proc_hidden')
      end

      it 'uses the same tags and operationIds' do
        legacy_ops.each do |key, op|
          expect(oas_ops[key]['tags']).to eq(op['tags'])
          expect(oas_ops[key]['operationId']).to eq(op['operationId'])
        end
        expect(oas_ops[['/api/v1/widgets/{id}', 'patch']]['tags']).to eq(%w[custom_tag])
      end

      it 'merges user tags the same way' do
        expect(oas['tags']).to eq(legacy['tags'])
        expect(oas['tags']).to include(include('name' => 'widgets', 'description' => 'User widgets'))
      end

      it 'uses the same response status codes' do
        legacy_ops.each do |key, op|
          expect(oas_ops[key]['responses'].keys).to eq(op['responses'].keys)
        end
        expect(oas_ops[['/api/v1/things', 'post']]['responses'].keys).to eq(%w[202 400 409])
        expect(oas_ops[['/api/v1/widgets', 'get']]['responses'].keys).to include('default')
      end

      it 'uses the same parameter names, without hidden parameters' do
        legacy_ops.each do |key, op|
          legacy_names = (op['parameters'] || []).map { |p| p['name'] }
          oas_names = (oas_ops[key]['parameters'] || []).map { |p| p['name'] }
          content = oas_ops[key].dig('requestBody', 'content') || {}
          body_props = (content.values.first || {}).dig('schema', 'properties')&.keys || []
          expect((oas_names + body_props).sort).to eq(legacy_names.reject { |n| n == 'body' }.sort), key.inspect
        end
        all = oas_ops.values.flat_map { |o| (o['parameters'] || []).map { |p| p['name'] } }
        expect(all).not_to include('secret', 'hidden_opt')
      end

      it 'maps produces and consumes to response and request content types' do
        legacy_ops.each do |key, op|
          media = oas_ops[key]['responses'].values.flat_map { |r| (r['content'] || {}).keys }.uniq
          expect(media - op['produces']).to be_empty
          next unless op['consumes']

          expect((oas_ops[key].dig('requestBody', 'content') || {}).keys - op['consumes']).to be_empty
        end
        expect(legacy_ops[['/api/v1/things/upload', 'put']]['produces']).to eq(['application/xml'])
        expect(legacy_ops[['/api/v1/things/download', 'get']]['produces']).to eq(['application/octet-stream'])
      end
    end
  end

  context 'when route tags are an empty list' do
    let(:app) do
      Class.new(Grape::API) do
        desc 'No tags', tags: []
        get('/gadgets') { {} }
        add_swagger_documentation openapi_version: '3.0'
      end
    end

    it 'derives the tag from the path like Swagger 2.0' do
      get '/swagger_doc'
      expect(JSON.parse(last_response.body).dig('paths', '/gadgets', 'get', 'tags')).to eq(%w[gadgets])
    end
  end

  # Documented difference (docs/openapi_3.md): 2.0 reads tags from the first operation of each path and
  # emits nothing for user tags when the API has no routes; 3.x collects tags from every operation.
  context 'when collecting the tag list' do
    def doc(version, routes = proc {})
      api = Class.new(Grape::API) do
        format :json
        class_exec(&routes)
        options = { tags: [{ name: 'user_tag', description: 'User' }] }
        options[:openapi_version] = version if version
        add_swagger_documentation(options)
      end
      JSON.parse(Rack::MockRequest.new(api).get('/swagger_doc').body)
    end

    it 'emits user tags for an API without routes in 3.x only' do
      expect(doc(nil)['tags']).to be_nil
      expect(doc('3.0')['tags']).to eq([{ 'name' => 'user_tag', 'description' => 'User' }])
    end

    it 'collects derived tags from every operation of a path in 3.x only' do
      routes = proc do
        desc 'One', tags: %w[first]
        get('/pair') { {} }
        desc 'Two', tags: %w[second]
        post('/pair') { {} }
      end

      expect(doc(nil, routes)['tags'].map { |t| t['name'] }).not_to include('second')
      expect(doc('3.0', routes)['tags'].map { |t| t['name'] }).to include('first', 'second')
    end
  end
end
