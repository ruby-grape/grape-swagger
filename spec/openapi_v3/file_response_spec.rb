# frozen_string_literal: true

require 'spec_helper'

describe 'File responses in OAS 3.x output' do
  before :all do
    module FileResponseOAS3
      class API < Grape::API
        format :json

        desc 'Download', success: File
        get('/download') { 'data' }

        add_swagger_documentation(openapi_version: '3.0')
      end
    end
  end

  def app
    FileResponseOAS3::API
  end

  it 'documents the download as binary octet-stream content' do
    get '/swagger_doc'
    content = JSON.parse(last_response.body)['paths']['/download']['get']['responses']['200']['content']

    expect(content).to eq('application/octet-stream' => { 'schema' => { 'type' => 'string', 'format' => 'binary' } })
  end
end
