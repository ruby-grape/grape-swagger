# frozen_string_literal: true

require 'spec_helper'

describe '#582 respond with a file' do
  include_context "#{MODEL_PARSER} swagger example"

  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_582 do
        desc 'produces given',
             success: File,
             produces: ['application/pdf', 'text/csv']
        get '/produces_given' do
          'responds a file'
        end

        desc 'automatic produces',
             success: 'file'
        get '/automatic_produces' do
          'responds a file'
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'produces given' do
    let(:produces) { subject['paths']['/issue_582/produces_given']['get']['produces'] }
    let(:response) { subject['paths']['/issue_582/produces_given']['get']['responses']['200'] }

    specify do
      expect(produces).to eql ['application/pdf', 'text/csv']
      expect(response).to include 'schema'
      expect(response['schema']).to eql 'type' => 'file'
    end
  end

  describe 'automatic_produces' do
    let(:produces) { subject['paths']['/issue_582/automatic_produces']['get']['produces'] }
    let(:response) { subject['paths']['/issue_582/automatic_produces']['get']['responses']['200'] }

    specify do
      expect(produces).to eql ['application/octet-stream']
      expect(response).to include 'schema'
      expect(response['schema']).to eql 'type' => 'file'
    end
  end
end
