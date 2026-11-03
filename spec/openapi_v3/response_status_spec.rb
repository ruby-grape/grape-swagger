# frozen_string_literal: true

require 'spec_helper'

describe 'Response status codes in OAS 3.x output' do
  before :all do
    module ResponseStatusOAS3
      class Item < Grape::Entity
        expose :id, documentation: { type: Integer }
      end

      class Problem < Grape::Entity
        expose :message, documentation: { type: String }
      end

      class API < Grape::API
        format :json

        desc 'Symbolic success and failure',
             success: { code: :created, model: Item },
             failure: [[:not_found, 'Missing', Problem], [:bad_request, 'Invalid', Problem]]
        get('/symbolic') { {} }

        desc 'Symbolic http_codes',
             http_codes: [[:ok, 'Fine', Item], [:conflict, 'Taken', Problem]]
        get('/http_codes') { {} }

        desc 'Typo in symbolic status',
             failure: [[:not_foud, 'Typo', Problem], [:bad_request, 'Invalid', Problem]]
        get('/typo') { {} }

        desc 'Typo in success status', success: { code: :creatd, model: Item }
        get('/success_typo') { {} }

        add_swagger_documentation(openapi_version: '3.0')
      end
    end
  end

  def app
    ResponseStatusOAS3::API
  end

  before { GrapeSwagger::OpenAPI::Builder::ResponseBuilder::WARNED_STATUSES.clear }

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  it 'normalizes symbolic success and failure statuses to HTTP codes' do
    expect(subject['paths']['/symbolic']['get']['responses'].keys).to eq(%w[201 404 400])
  end

  it 'normalizes symbolic http_codes entries to HTTP codes' do
    expect(subject['paths']['/http_codes']['get']['responses'].keys).to eq(%w[200 409])
  end

  it 'warns about an unknown symbolic status and skips that response' do
    expect { subject }.to output(/:not_foud/).to_stderr
    expect(subject['paths']['/typo']['get']['responses'].keys).to eq(%w[200 400])
  end

  it 'falls back to the default success status for an unknown success symbol' do
    expect { subject }.to output(/:creatd.*default success status 200/).to_stderr
    expect(subject['paths']['/success_typo']['get']['responses'].keys).to eq(%w[200])
  end

  it 'warns once per symbol' do
    expect { 2.times { get '/swagger_doc' } }.to output(/\A(?:(?!:not_foud).)*:not_foud(?:(?!:not_foud).)*\z/m).to_stderr
  end

  it 'warns once per symbol when documentation is built from several threads' do
    builder = Class.new { include GrapeSwagger::OpenAPI::Builder::ResponseBuilder }.new

    expect do
      Array.new(8) { Thread.new { builder.send(:warn_unknown_status, :not_foud_threaded, 'skipped') } }.each(&:join)
    end.to output(/\Agrape-swagger: unknown response status :not_foud_threaded; skipped\n\z/).to_stderr
  end
end
