# frozen_string_literal: true

require 'spec_helper'

describe 'Form data in OpenAPI 3.0' do
  before :all do
    module TheApi
      class FormDataOAS3Api < Grape::API
        format :json

        desc 'Login with form data',
             consumes: ['application/x-www-form-urlencoded']
        params do
          requires :username, type: String, desc: 'Username'
          requires :password, type: String, desc: 'Password'
          optional :remember_me, type: Boolean, desc: 'Remember me'
        end
        post '/login' do
          { token: 'abc123' }
        end

        desc 'Upload with multipart form',
             consumes: ['multipart/form-data']
        params do
          requires :file, type: File, desc: 'File to upload'
          requires :name, type: String, desc: 'File name'
          optional :description, type: String, desc: 'File description'
        end
        post '/upload' do
          { uploaded: true }
        end

        desc 'Mixed params with form data'
        params do
          requires :id, type: Integer, desc: 'Resource ID'
        end
        post '/items/:id' do
          params do
            requires :name, type: String, desc: 'Item name'
          end
          { id: params[:id] }
        end

        add_swagger_documentation(openapi_version: '3.0')
      end
    end
  end

  def app
    TheApi::FormDataOAS3Api
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'URL-encoded form data' do
    let(:login_op) { subject['paths']['/login']['post'] }

    it 'converts formData to requestBody' do
      expect(login_op).to have_key('requestBody')
      expect(login_op).not_to have_key('parameters')
    end

    it 'uses application/x-www-form-urlencoded content type' do
      content = login_op['requestBody']['content']
      expect(content).to have_key('application/x-www-form-urlencoded')
    end

    it 'includes all form fields as schema properties' do
      schema = login_op['requestBody']['content']['application/x-www-form-urlencoded']['schema']
      expect(schema['properties']).to have_key('username')
      expect(schema['properties']).to have_key('password')
      expect(schema['properties']).to have_key('remember_me')
    end

    it 'marks required fields in schema' do
      schema = login_op['requestBody']['content']['application/x-www-form-urlencoded']['schema']
      expect(schema['required']).to include('username')
      expect(schema['required']).to include('password')
      expect(schema['required']).not_to include('remember_me')
    end

    it 'preserves field types' do
      schema = login_op['requestBody']['content']['application/x-www-form-urlencoded']['schema']
      expect(schema['properties']['username']['type']).to eq('string')
      expect(schema['properties']['remember_me']['type']).to eq('boolean')
    end

    it 'sets requestBody as required when has required fields' do
      expect(login_op['requestBody']['required']).to be true
    end
  end

  describe 'multipart form data with file' do
    let(:upload_op) { subject['paths']['/upload']['post'] }

    it 'converts formData to requestBody' do
      expect(upload_op).to have_key('requestBody')
    end

    it 'uses multipart/form-data content type' do
      content = upload_op['requestBody']['content']
      expect(content).to have_key('multipart/form-data')
    end

    it 'converts file type to string with binary format' do
      schema = upload_op['requestBody']['content']['multipart/form-data']['schema']
      file_prop = schema['properties']['file']
      expect(file_prop['type']).to eq('string')
      expect(file_prop['format']).to eq('binary')
    end

    it 'includes non-file fields alongside file' do
      schema = upload_op['requestBody']['content']['multipart/form-data']['schema']
      expect(schema['properties']).to have_key('name')
      expect(schema['properties']['name']['type']).to eq('string')
    end
  end

  describe 'no formData parameters in output' do
    it 'does not have any parameters with in: formData' do
      json_string = subject.to_json
      expect(json_string).not_to include('"in":"formData"')
      expect(json_string).not_to include('"in": "formData"')
    end
  end
end
