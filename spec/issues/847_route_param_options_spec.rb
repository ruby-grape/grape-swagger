# frozen_string_literal: true

require 'spec_helper'

describe '#847 route_param type is included in documentation' do
  let(:app) do
    Class.new(Grape::API) do
      resource :accounts do
        route_param :account_number, type: String do
          resource :records do
            route_param :id do
              get do
                { message: 'hello world' }
              end
            end
          end
        end
      end

      add_swagger_documentation
    end
  end
  let(:parameters) { subject['paths']['/accounts/{account_number}/records/{id}']['get']['parameters'] }

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  specify do
    account_number_param = parameters.find { |param| param['name'] == 'account_number' }
    expect(account_number_param['type']).to eq 'string'
    id_param = parameters.find { |param| param['name'] == 'id' }
    # Default is still integer
    expect(id_param['type']).to eq 'integer'
  end
end
