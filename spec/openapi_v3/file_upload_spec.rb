# frozen_string_literal: true

require 'spec_helper'

describe 'File upload in OpenAPI 3.0' do
  before :all do
    module TheApi
      class FileUploadOAS3Api < Grape::API
        format :json

        desc 'Upload a file'
        params do
          requires :file, type: File, desc: 'The file to upload'
          optional :description, type: String, desc: 'File description'
        end
        post '/upload' do
          { filename: params[:file][:filename] }
        end

        desc 'Upload multiple files'
        params do
          requires :files, type: Array[File], desc: 'Multiple files to upload'
        end
        post '/upload_multiple' do
          { count: params[:files].length }
        end

        add_swagger_documentation(openapi_version: '3.0')
      end
    end
  end

  def app
    TheApi::FileUploadOAS3Api
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'single file upload' do
    let(:upload_op) { subject['paths']['/upload']['post'] }
    let(:schema) { subject['components']['schemas']['postUpload'] }

    it 'uses requestBody for file upload' do
      expect(upload_op).to have_key('requestBody')
    end

    it 'references schema in requestBody content' do
      content = upload_op['requestBody']['content']
      expect(content['application/json']['schema']['$ref']).to eq('#/components/schemas/postUpload')
    end

    it 'converts file type to string with binary format in schema' do
      file_prop = schema['properties']['file']

      expect(file_prop['type']).to eq('string')
      expect(file_prop['format']).to eq('binary')
      expect(file_prop['description']).to eq('The file to upload')
    end

    it 'marks file as required' do
      expect(schema['required']).to include('file')
    end
  end

  describe 'multiple file upload' do
    let(:schema) { subject['components']['schemas']['postUploadMultiple'] }

    it 'handles array of files with binary format' do
      files_prop = schema['properties']['files']

      expect(files_prop['type']).to eq('array')
      expect(files_prop['items']['type']).to eq('string')
      expect(files_prop['items']['format']).to eq('binary')
    end
  end
end
