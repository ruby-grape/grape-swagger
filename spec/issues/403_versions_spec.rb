# encoding: utf-8
require 'spec_helper'

describe 'describing versions' do
  describe 'nothings given' do
    def app
      Class.new(Grape::API) do
        desc 'no versions given'
        get '/nothings' do
          { message: 'hello world …' }
        end

        add_swagger_documentation format: :json
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body, symbolize_names: true)
    end

    specify do
      expect(subject).to eql(
        info: { title: 'API title', version: '0.0.1' },
        swagger: '2.0',
        produces: ['application/xml', 'application/json', 'application/octet-stream', 'text/plain'],
        host: 'example.org',
        tags: [{ name: 'nothings', description: 'Operations about nothings' }],
        paths: {
          :'/nothings' => {
            get: {
              description: 'no versions given',
              produces: ['application/json'],
              responses: {
                :'200' => { description: 'no versions given' }
              },
              tags: ['nothings'],
              operationId: 'getNothings'
            } } })
    end
  end

  describe 'API version given' do
    def app
      Class.new(Grape::API) do
        version 'v2', using: :path
        desc 'api versions given'
        get '/api_version' do
          { message: 'hello world …' }
        end

        add_swagger_documentation format: :json
      end
    end

    subject do
      get '/v2/swagger_doc'
      JSON.parse(last_response.body, symbolize_names: true)
    end

    specify do
      expect(subject).to eql(
        info: { title: 'API title', version: '0.0.1' },
        swagger: '2.0',
        produces: ['application/xml', 'application/json', 'application/octet-stream', 'text/plain'],
        host: 'example.org',
        tags: [{ name: 'api_version', description: 'Operations about api_versions' }],
        paths: {
          :'/v2/api_version' => {
            get: {
              description: 'api versions given',
              produces: ['application/json'],
              responses: {
                :'200' => { description: 'api versions given' }
              },
              tags: ['api_version'],
              operationId: 'getV2ApiVersion'
            } } })
    end
  end

  describe 'DOC version given' do
    def app
      Class.new(Grape::API) do
        desc 'doc versions given'
        get '/doc_version' do
          { message: 'hello world …' }
        end

        add_swagger_documentation doc_version: '0.0.2'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body, symbolize_names: true)
    end

    specify do
      expect(subject).to eql(
        info: { title: 'API title', version: '0.0.2' },
        swagger: '2.0',
        produces: ['application/xml', 'application/json', 'application/octet-stream', 'text/plain'],
        host: 'example.org',
        tags: [{ name: 'doc_version', description: 'Operations about doc_versions' }],
        paths: {
          :'/doc_version' => {
            get: {
              description: 'doc versions given',
              produces: ['application/json'],
              responses: {
                :'200' => { description: 'doc versions given' }
              },
              tags: ['doc_version'],
              operationId: 'getDocVersion'
            } } })
    end
  end

  describe 'both versions given' do
    def app
      Class.new(Grape::API) do
        version :v2, using: :path
        desc 'both versions given'
        get '/both_versions' do
          { message: 'hello world …' }
        end

        add_swagger_documentation doc_version: '0.0.2'
      end
    end

    subject do
      get '/v2/swagger_doc'
      JSON.parse(last_response.body, symbolize_names: true)
    end

    specify do
      expect(subject).to eql(
        info: { title: 'API title', version: '0.0.2' },
        swagger: '2.0',
        produces: ['application/xml', 'application/json', 'application/octet-stream', 'text/plain'],
        host: 'example.org',
        tags: [{ name: 'both_versions', description: 'Operations about both_versions' }],
        paths: {
          :'/v2/both_versions' => {
            get: {
              description: 'both versions given',
              produces: ['application/json'],
              responses: {
                :'200' => { description: 'both versions given' }
              },
              tags: ['both_versions'],
              operationId: 'getV2BothVersions'
            } } })
    end
  end
end
