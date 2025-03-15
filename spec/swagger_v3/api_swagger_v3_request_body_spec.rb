# frozen_string_literal: true

require 'spec_helper'

describe 'requestBody in OpenAPI 3.0' do
  include_context "#{MODEL_PARSER} swagger example"

  def app
    Class.new(Grape::API) do
      format :json

      desc 'Post something',
           success: Entities::Something
      params do
        requires :text, type: String, documentation: { desc: 'Content of something.' }
        requires :links, type: Array, documentation: { type: 'link', is_array: true }
      end
      post '/something' do
        something = OpenStruct.new text: 'something'
        present something, with: Entities::Something
      end

      desc 'Post with body param',
           success: Entities::Something
      params do
        requires :body, type: Hash do
          requires :text, type: String, documentation: { desc: 'Content of something.' }
          requires :links, type: Array, documentation: { type: 'link', is_array: true }
        end
      end
      post '/with_body_param' do
        something = OpenStruct.new text: 'something'
        present something, with: Entities::Something
      end

      add_swagger_documentation
    end
  end

  describe 'requestBody structure' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'has requestBody for POST endpoints' do
      expect(subject['paths']['/something']['post']).to have_key('requestBody')
      expect(subject['paths']['/with_body_param']['post']).to have_key('requestBody')
    end

    it 'has content in requestBody' do
      request_body = subject['paths']['/something']['post']['requestBody']
      expect(request_body).to have_key('content')
      expect(request_body['content']).to have_key('application/json')
      expect(request_body['content']['application/json']).to have_key('schema')
    end

    it 'has schema reference in requestBody content' do
      schema = subject['paths']['/something']['post']['requestBody']['content']['application/json']['schema']
      expect(schema).to have_key('$ref')
      expect(schema['$ref']).to start_with('#/components/schemas/')
    end

    it 'has required property in requestBody' do
      request_body = subject['paths']['/something']['post']['requestBody']
      expect(request_body).to have_key('required')
      expect(request_body['required']).to be true
    end
  end
end 