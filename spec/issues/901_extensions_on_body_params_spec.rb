# frozen_string_literal: true

require 'spec_helper'

describe '#901 params extension does not work when param_type is body' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_901 do
        params do
          requires :user_id, type: Integer, documentation: { type: 'integer', param_type: 'body', x: { nullable: true } }
          requires :friend_ids, type: [Integer], documentation: { type: 'integer', is_array: true, param_type: 'body', x: { type: 'array' }, items: { x: { type: 'item' } } }
          requires :address, type: Hash, documentation: { type: 'object', param_type: 'body', x: { type: 'address' } } do
            requires :city_id, type: Integer, documentation: { type: 'integer', x: { type: 'city' } }
          end
        end
        post do
          present params
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  let(:definition) { subject['definitions']['postIssue901'] }

  specify do
    expect(definition['properties']).to match(
      'user_id' => hash_including('type' => 'integer', 'x-nullable' => true),
      'address' => hash_including(
        'type' => 'object',
        'x-type' => 'address',
        'properties' => {
          'city_id' => hash_including('type' => 'integer', 'x-type' => 'city')
        }
      ),
      'friend_ids' => hash_including(
        'type' => 'array',
        'x-type' => 'array',
        'items' => hash_including('type' => 'integer', 'x-type' => 'item')
      )
    )
  end
end
