# frozen_string_literal: true

require 'spec_helper'

describe '#942 route param documentation' do
  let(:documentation) { { format: 'uuid' } }

  let(:app) do
    docs = documentation

    another_app = Class.new(Grape::API) do
      get '/list' do
        []
      end
    end

    Class.new(Grape::API) do
      route_param :account_id, type: String, desc: 'id of account', documentation: docs do
        mount another_app

        get '/another-list' do
          []
        end
      end

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  context 'when documenting route_param of mounted endpoint' do
    let(:parameters) { subject['paths']['/{account_id}/list']['get']['parameters'] }

    specify do
      account_id_param = parameters.find { |param| param['name'] == 'account_id' }
      expect(account_id_param['type']).to eq 'string'
      expect(account_id_param['format']).to eq 'uuid'
      expect(account_id_param['description']).to eq 'id of account'
    end
  end

  context 'when documenting route_param of nested endpoint' do
    let(:parameters) { subject['paths']['/{account_id}/another-list']['get']['parameters'] }

    specify do
      account_id_param = parameters.find { |param| param['name'] == 'account_id' }
      expect(account_id_param['type']).to eq 'string'
      expect(account_id_param['format']).to eq 'uuid'
      expect(account_id_param['description']).to eq 'id of account'
    end
  end

  context 'when documentation overrides description' do
    let(:documentation) { { desc: 'another description' } }

    let(:parameters) { subject['paths']['/{account_id}/list']['get']['parameters'] }

    specify do
      account_id_param = parameters.find { |param| param['name'] == 'account_id' }
      expect(account_id_param['type']).to eq 'string'
      expect(account_id_param['description']).to eq 'another description'
    end
  end
end
