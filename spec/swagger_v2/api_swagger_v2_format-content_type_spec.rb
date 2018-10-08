# frozen_string_literal: true

require 'spec_helper'

describe 'format, content_type' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class ProducesApi < Grape::API
        format :json

        desc 'This uses json (default) for produces',
             failure: [{ code: 400, model: Entities::ApiError }],
             entity: Entities::UseResponse
        get '/use_default' do
          { 'declared_params' => declared(params) }
        end

        desc 'This uses formats for produces',
             failure: [{ code: 400, model: Entities::ApiError }],
             formats: [:xml, :binary, 'application/vdns'],
             entity: Entities::UseResponse
        get '/use_formats' do
          { 'declared_params' => declared(params) }
        end

        desc 'This uses content_types for produces',
             failure: [{ code: 400, model: Entities::ApiError }],
             content_types: [:xml, :binary, 'application/vdns'],
             entity: Entities::UseResponse
        get '/use_content_types' do
          { 'declared_params' => declared(params) }
        end

        desc 'This uses produces for produces',
             failure: [{ code: 400, model: Entities::ApiError }],
             produces: [:xml, :binary, 'application/vdns'],
             entity: Entities::UseResponse
        get '/use_produces' do
          { 'declared_params' => declared(params) }
        end

        desc 'This uses consumes for consumes',
             failure: [{ code: 400, model: Entities::ApiError }],
             consumes: ['application/www_url_encoded'],
             entity: Entities::UseResponse
        post '/use_consumes' do
          { 'declared_params' => declared(params) }
        end

        desc 'This uses consumes for consumes',
             failure: [{ code: 400, model: Entities::ApiError }],
             consumes: ['application/www_url_encoded'],
             entity: Entities::UseResponse
        patch '/use_consumes' do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::ProducesApi
  end

  let(:produced) do
    [
      'application/xml',
      'application/octet-stream',
      'application/vdns'
    ]
  end

  describe 'formats' do
    subject do
      get '/swagger_doc/use_default'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/use_default']['get']).to include('produces')
      expect(subject['paths']['/use_default']['get']['produces']).to eql(['application/json'])
    end
  end

  describe 'formats' do
    subject do
      get '/swagger_doc/use_formats'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/use_formats']['get']).to include('produces')
      expect(subject['paths']['/use_formats']['get']['produces']).to eql(produced)
    end
  end

  describe 'content types' do
    subject do
      get '/swagger_doc/use_content_types'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/use_content_types']['get']).to include('produces')
      expect(subject['paths']['/use_content_types']['get']['produces']).to eql(produced)
    end
  end

  describe 'produces' do
    subject do
      get '/swagger_doc/use_produces'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/use_produces']['get']).to include('produces')
      expect(subject['paths']['/use_produces']['get']['produces']).to eql(produced)
    end
  end

  describe 'consumes' do
    subject do
      get '/swagger_doc/use_consumes'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/use_consumes']['post']).to include('consumes')
      expect(subject['paths']['/use_consumes']['post']['consumes']).to eql ['application/www_url_encoded']
      expect(subject['paths']['/use_consumes']['patch']['consumes']).to eql ['application/www_url_encoded']
    end
  end
end
