# frozen_string_literal: true

require 'spec_helper'

describe 'hidden hash parameter' do
  let(:app) do
    Class.new(Grape::API) do
      format :json

      params do
        optional :query, type: String
        optional :filters, type: Hash, documentation: { hidden: true } do
          optional :status, type: String
          optional :nested, type: Hash do
            optional :kind, type: String
          end
        end
        optional :other, type: Hash do
          optional :visible, type: String
        end
      end
      get('/search') { 'ok' }

      add_swagger_documentation
    end
  end

  it 'hides the nested children together with the parent' do
    get '/swagger_doc'
    names = JSON.parse(last_response.body).dig('paths', '/search', 'get', 'parameters').map { |p| p['name'] }
    expect(names).to eq(['query', 'other[visible]'])
  end
end
