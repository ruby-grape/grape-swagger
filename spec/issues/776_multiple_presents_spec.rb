# frozen_string_literal: true

require 'spec_helper'

describe '#776 multiple presents spec' do
  include_context "#{MODEL_PARSER} swagger example"

  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_776 do
        desc 'Get multiple presents',
             success: [
               { model: Entities::EnumValues, as: :gender },
               { model: Entities::Something, as: :somethings, is_array: true, required: true }
             ]

        get do
          present :gender, { number: 1, gender: 'Male' }, with: Entities::EnumValues
          present :somethings, [
            { id: 1, text: 'element_1', links: %w[link1 link2] },
            { id: 2, text: 'element_2', links: %w[link1 link2] }
          ], with: Entities::Something, is_array: true
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  let(:definitions) { subject['definitions'] }
  let(:schema) { subject['paths']['/issue_776']['get']['responses']['200']['schema'] }

  specify { expect(definitions.keys).to include 'EnumValues', 'Something' }

  specify do
    expect(schema).to eql({
      'properties' => {
        'somethings' => {
          'items' => {
            '$ref' => '#/definitions/Something'
          },
          'type' => 'array'
        },
        'gender' => {
          '$ref' => '#/definitions/EnumValues'
        }
      },
      'type' => 'object',
      'required' => [
        'somethings'
      ]
    })
  end
end
