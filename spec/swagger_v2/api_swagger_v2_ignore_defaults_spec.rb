# frozen_string_literal: true

require 'spec_helper'

describe 'swagger spec v2.0' do
  include_context "#{MODEL_PARSER} swagger example"

  def app
    Class.new(Grape::API) do
      format :json

      desc 'This creates Thing after a delay',
           success: { code: 202, message: 'OK', model: Entities::Something }
      params do
        requires :text, type: String, documentation: { type: 'string', desc: 'Content of something.' }
        requires :links, type: Array, documentation: { type: 'link', is_array: true }
      end
      post '/delay_thing' do
        status 202
      end

      version 'v3', using: :path
      add_swagger_documentation api_version: 'v1',
                                base_path: '/api',
                                info: {
                                  title: 'The API title to be displayed on the API homepage.',
                                  description: 'A description of the API.',
                                  contact_name: 'Contact name',
                                  contact_email: 'Contact@email.com',
                                  contact_url: 'Contact URL',
                                  license: 'The name of the license.',
                                  license_url: 'www.The-URL-of-the-license.org',
                                  terms_of_service_url: 'www.The-URL-of-the-terms-and-service.com'
                                }
    end
  end

  before do
    get '/v3/swagger_doc'
  end

  let(:json) { JSON.parse(last_response.body) }

  it 'only returns one response if ignore_defaults is specified' do
    expect(json['paths']['/delay_thing']['post']['responses']).to eq('202' => { 'description' => 'OK', 'schema' => { '$ref' => '#/definitions/Something' } })
    expect(json['paths']['/delay_thing']['post']['responses'].keys).not_to include '201'
  end
end
