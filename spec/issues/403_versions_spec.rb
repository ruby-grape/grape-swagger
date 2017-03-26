# encoding: utf-8
# frozen_string_literal: true

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
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['info']['version']).to eql '0.0.1'
      expect(subject['paths'].keys.first).to eql '/nothings'
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
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['info']['version']).to eql '0.0.1'
      expect(subject['paths'].keys.first).to eql '/v2/api_version'
    end
  end

  describe 'DOC version given' do
    def app
      Class.new(Grape::API) do
        desc 'doc versions given'
        get '/doc_version' do
          { message: 'hello world …' }
        end

        add_swagger_documentation doc_version: '0.1'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['info']['version']).to eql '0.1'
      expect(subject['paths'].keys.first).to eql '/doc_version'
    end
  end

  describe 'both versions given' do
    def app
      Class.new(Grape::API) do
        version :v3, using: :path
        desc 'both versions given'
        get '/both_versions' do
          { message: 'hello world …' }
        end

        add_swagger_documentation doc_version: '0.2'
      end
    end

    subject do
      get '/v3/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['info']['version']).to eql '0.2'
      expect(subject['paths'].keys.first).to eql '/v3/both_versions'
    end
  end

  describe 'try to override grape given version' do
    def app
      Class.new(Grape::API) do
        version :v4, using: :path
        desc 'overriding grape given version?'
        get '/grape_version' do
          { message: 'hello world …' }
        end

        add_swagger_documentation doc_version: '0.0.3',
                                  version: 'v5'
      end
    end

    subject do
      get '/v4/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['info']['version']).to eql '0.0.3'
      expect(subject['paths'].keys.first).to eql '/v4/grape_version'
    end
  end
end
