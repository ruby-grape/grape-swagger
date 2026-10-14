# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3 tag externalDocs' do
  before :all do
    module TheApi
      class OAS3TagDocsApi < Grape::API
        format :json
        get('/something') { {} }
        add_swagger_documentation(
          openapi_version: '3.0',
          tags: [{ name: 'something', description: 'Things',
                   externalDocs: { url: 'https://example.com/docs', description: 'More' } }]
        )
      end
    end
  end

  it 'keeps externalDocs on user-supplied tags' do
    env = Rack::MockRequest.env_for('/swagger_doc')
    doc = JSON.parse(TheApi::OAS3TagDocsApi.call(env)[2].each.to_a.join)
    tag = doc['tags'].find { |t| t['name'] == 'something' }
    expect(tag['externalDocs']).to eq('url' => 'https://example.com/docs', 'description' => 'More')
  end
end
