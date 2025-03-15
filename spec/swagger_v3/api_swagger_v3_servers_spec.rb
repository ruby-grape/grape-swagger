# frozen_string_literal: true

require 'spec_helper'

describe 'servers in OpenAPI 3.0' do
  def app
    Class.new(Grape::API) do
      format :json

      desc 'Get something'
      get '/something' do
        { text: 'something' }
      end

      add_swagger_documentation host: 'example.org',
                               base_path: '/api/v1',
                               info: { title: 'Swagger Test' }
    end
  end

  describe 'servers object' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'has servers array' do
      expect(subject).to have_key('servers')
      expect(subject['servers']).to be_an(Array)
      expect(subject['servers'].length).to eq(1)
    end

    it 'has correct server URL' do
      server = subject['servers'].first
      expect(server).to have_key('url')
      expect(server['url']).to eq('http://example.org/api/v1')
    end

    it 'does not have host and basePath' do
      expect(subject).not_to have_key('host')
      expect(subject).not_to have_key('basePath')
    end
  end
end 