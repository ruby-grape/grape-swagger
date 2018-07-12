# frozen_string_literal: true

require 'spec_helper'

describe 'when the main endpoint response is a 204 all error schemas are lost' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_680 do
        desc 'delete something',
             is_array: true,
             success: { status: 204 },
             failure: [
               [401, 'Unauthorized', Entities::ApiError],
               [403, 'Forbidden', Entities::ApiError],
               [404, 'Not Found', Entities::ApiError]
             ]

        delete do
          status 204
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  context 'when an endpoint can return a 204' do
    let(:responses) { subject['paths']['/issue_680']['delete']['responses'] }

    it 'returns the description but not a schema for a 204 response' do
      expect(responses['204']['description']).to eq('delete something')
      expect(responses['204']['schema']).to be_nil
    end

    it 'returns a description AND a schema for a 401 response' do
      expect(responses['401']['description']).to eq('Unauthorized')
      expect(responses['401']['schema']).to_not be_nil
    end

    it 'returns a description AND a schema for a 403 response' do
      expect(responses['403']['description']).to eq('Forbidden')
      expect(responses['403']['schema']).to_not be_nil
    end

    it 'returns a description AND a schema for a 404 response' do
      expect(responses['404']['description']).to eq('Not Found')
      expect(responses['404']['schema']).to_not be_nil
    end
  end
end
