# frozen_string_literal: true

require 'spec_helper'

describe 'Errors' do
  describe 'Empty model error' do
    let!(:app) do
      Class.new(Grape::API) do
        format :json

        desc 'Empty model get.' do
          http_codes [
            { code: 200, message: 'get Empty model', model: EmptyClass }
          ]
        end
        get '/empty_model' do
          something = OpenStruct.new text: 'something'
          present something, with: EmptyClass
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

    it 'should raise SwaggerSpec exception' do
      expect { get '/v3/swagger_doc' }.to raise_error(GrapeSwagger::Errors::SwaggerSpec, "Empty model EmptyClass, swagger 2.0 doesn't support empty definitions.")
    end
  end

  describe 'Parser not found error' do
    let!(:app) do
      Class.new(Grape::API) do
        format :json

        desc 'Wrong model get.' do
          http_codes [
            { code: 200, message: 'get Wrong model', model: Hash }
          ]
        end
        get '/wrong_model' do
          something = OpenStruct.new text: 'something'
          present something, with: Hash
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

    it 'should raise UnregisteredParser exception' do
      expect { get '/v3/swagger_doc' }.to raise_error(GrapeSwagger::Errors::UnregisteredParser, 'No parser registered for Hash.')
    end
  end
end
