# frozen_string_literal: true

require 'spec_helper'

describe '#923 Body params for DELETE action' do
  let(:app) do
    Class.new(Grape::API) do
      params do
        requires :post_id, type: Integer
        requires :query, type: String, documentation: { type: 'string', param_type: 'body' }
      end
      delete '/posts/:post_id/comments' do
        { 'declared_params' => declared(params) }
      end
      add_swagger_documentation format: :json
    end
  end

  describe 'retrieves the documentation for delete parameters as a schema defintion' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/posts/{post_id}/comments']['delete']['parameters']).to match(
        [
          {
            'format' => 'int32',
            'in' => 'path',
            'name' => 'post_id',
            'type' => 'integer',
            'required' => true
          },
          {
            'name' => 'deletePostsPostIdComments',
            'in' => 'body',
            'required' => true,
            'schema' => { '$ref' => '#/definitions/deletePostsPostIdComments' }
          }
        ]
      )

      expect(subject['definitions']['deletePostsPostIdComments']).to match(
        'type' => 'object',
        'properties' => {
          'query' => {
            'type' => 'string'
          }
        },
        'required' => ['query']
      )
    end
  end
end
