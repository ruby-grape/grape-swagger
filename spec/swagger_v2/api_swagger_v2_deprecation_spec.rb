require 'spec_helper'

describe 'swagger spec v2.0 deprecation' do
  include_context "#{MODEL_PARSER} swagger example"

  def app
    Class.new(Grape::API) do
      format :json

      desc 'This is a test sample', deprecated: true
      get '/old' do
        present true
      end

      desc 'This is another test sample', deprecated: false
      get '/new' do
        present true
      end

      version 'v1', using: :path
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
    get '/v1/swagger_doc'
  end

  let(:json) { JSON.parse(last_response.body) }

  describe 'deprecation' do
    it { expect(json['paths']['/old']['get']['deprecated']).to eql true }
    it { expect(json['paths']['/new']['get']).to_not include 'deprecated' }
  end
end
