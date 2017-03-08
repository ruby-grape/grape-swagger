# frozen_string_literal: true
require 'spec_helper'

describe '#572 is_array is applied to all possible responses' do
  include_context "#{MODEL_PARSER} swagger example"

  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_572 do
        desc 'get issue',
             is_array: true,
             success: Entities::UseResponse,
             failure: [
               [401, 'BadKittenError', Entities::ApiError],
               [404, 'NoTreatsError', Entities::ApiError],
               [429, 'TooManyScratchesError', Entities::ApiError]
             ]

        get
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  let(:codes) { %w(200 401 404 429) }

  let(:responses) { subject['paths']['/issue_572']['get']['responses'] }

  specify { expect(responses.keys.sort).to eq codes }

  specify do
    expect(responses['200']['schema']).to include 'type'
    expect(responses['200']['schema']['type']).to eql 'array'
  end

  describe 'no array types' do
    specify do
      codes[1..-1].each do |code|
        expect(responses[code]['schema']).not_to include 'type'
        expect(responses[code]['schema'].keys).to eql ['$ref']
      end
    end
  end
end
