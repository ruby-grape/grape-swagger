# frozen_string_literal: true

require 'spec_helper'

describe '#721 set default parameter location based on consumes' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_721 do
        desc 'create item' do
          consumes ['application/json']
        end

        params do
          requires :logs, type: String
          optional :phone_number, type: Integer
        end

        post do
          present params
        end

        desc 'modify item' do
          consumes ['application/x-www-form-urlencoded']
        end

        params do
          requires :id, type: Integer
          requires :logs, type: String
          optional :phone_number, type: Integer
        end

        put ':id' do
          present params
        end
      end

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  let(:post_parameters) { subject['paths']['/issue_721']['post']['parameters'] }
  let(:post_schema) { subject['definitions']['postIssue721'] }
  let(:put_parameters) { subject['paths']['/issue_721/{id}']['put']['parameters'] }

  specify do
    expect(post_parameters).to eql(
      [{ 'in' => 'body', 'name' => 'postIssue721', 'required' => true, 'schema' => { '$ref' => '#/definitions/postIssue721' } }]
    )
    expect(post_schema).to eql(
      { 'description' => 'create item', 'properties' => { 'logs' => { 'type' => 'string' }, 'phone_number' => { 'format' => 'int32', 'type' => 'integer' } }, 'required' => ['logs'], 'type' => 'object' }
    )
    puts put_parameters
    expect(put_parameters).to eql(
      [{ 'in' => 'path', 'name' => 'id', 'type' => 'integer', 'format' => 'int32', 'required' => true }, { 'in' => 'formData', 'name' => 'logs', 'type' => 'string', 'required' => true }, { 'in' => 'formData', 'name' => 'phone_number', 'type' => 'integer', 'format' => 'int32', 'required' => false }]
    )
  end
end
