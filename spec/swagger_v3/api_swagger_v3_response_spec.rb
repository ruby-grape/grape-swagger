# frozen_string_literal: true

require 'spec_helper'

describe 'response in OpenAPI 3.0' do
  include_context "#{MODEL_PARSER} swagger example"

  def app
    Class.new(Grape::API) do
      format :json

      desc 'Get something',
           success: Entities::Something
      get '/something' do
        something = OpenStruct.new text: 'something'
        present something, with: Entities::Something
      end

      desc 'Get something with examples',
           success: { model: Entities::Something, examples: { 'application/json' => { text: 'example text' } } }
      get '/something_with_examples' do
        something = OpenStruct.new text: 'something'
        present something, with: Entities::Something
      end

      desc 'Get file',
           success: File
      get '/file' do
        content_type 'application/octet-stream'
        header['Content-Disposition'] = 'attachment; filename=file.txt'
        body 'file content'
      end

      add_swagger_documentation
    end
  end

  describe 'response structure' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'has content-based response structure' do
      expect(subject['paths']['/something']['get']['responses']['200']).to have_key('content')
      expect(subject['paths']['/something']['get']['responses']['200']['content']).to have_key('application/json')
      expect(subject['paths']['/something']['get']['responses']['200']['content']['application/json']).to have_key('schema')
    end

    it 'has schema reference in content' do
      schema = subject['paths']['/something']['get']['responses']['200']['content']['application/json']['schema']
      expect(schema).to have_key('$ref')
      expect(schema['$ref']).to eq('#/components/schemas/Something')
    end

    it 'has examples in content' do
      examples = subject['paths']['/something_with_examples']['get']['responses']['200']['content']['application/json']['examples']
      expect(examples).to eq({ 'application/json' => { 'text' => 'example text' } })
    end

    it 'has file response with binary format' do
      file_response = subject['paths']['/file']['get']['responses']['200']['content']['application/octet-stream']
      expect(file_response['schema']).to eq({ 'type' => 'string', 'format' => 'binary' })
    end
  end
end 