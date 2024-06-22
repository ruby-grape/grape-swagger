# frozen_string_literal: true

require 'spec_helper'

describe '#533 specify status codes' do
  include_context "#{MODEL_PARSER} swagger example"

  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_533 do
        desc 'Get a list of stuff',
             success: { code: 202, model: Entities::UseResponse, message: 'a changed status code' }
        get do
          status 202
          { foo: 'that is the response' }
        end

        desc 'Post some stuff',
             success: { code: 202, model: Entities::UseResponse, message: 'a changed status code' }
        post do
          status 202
          { foo: 'that is the response' }
        end

        desc 'Post some stuff',
             success: { code: 204, message: 'a changed status code' }
        patch do
          status 204
          body false
        end

        desc 'Delete some stuff',
             success: { code: 203 }
        delete do
          status 203
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)['paths']['/issue_533']
  end

  let(:get_response) { get '/issue_533' }
  specify { expect(get_response.status).to eql 202 }
  let(:get_response_documentation) { subject['get']['responses'] }
  specify do
    expect(get_response_documentation.keys.first).to eql '202'
    expect(get_response_documentation['202']).to include 'schema'
  end

  let(:post_response) { post '/issue_533' }
  specify { expect(post_response.status).to eql 202 }
  let(:post_response_documentation) { subject['post']['responses'] }
  specify do
    expect(post_response_documentation.keys.first).to eql '202'
    expect(post_response_documentation['202']).to include 'schema'
  end

  let(:patch_response) { patch '/issue_533' }
  specify { expect(patch_response.status).to eql 204 }
  let(:patch_response_documentation) { subject['patch']['responses'] }
  specify do
    expect(patch_response_documentation.keys.first).to eql '204'
    expect(patch_response_documentation['204']).not_to include 'schema'
  end

  let(:delete_response) { delete '/issue_533' }
  specify { expect(delete_response.status).to eql 203 }
  let(:delete_response_documentation) { subject['delete']['responses'] }
  specify do
    expect(delete_response_documentation.keys.first).to eql '203'
    expect(delete_response_documentation['203']).not_to include 'schema'
  end
end
