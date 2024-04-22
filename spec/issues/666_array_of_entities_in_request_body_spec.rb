# frozen_string_literal: true

require 'spec_helper'

describe 'definition names' do
  before :all do
    module TestDefinition
      module Entity
        class Account < Grape::Entity
          expose :cma, documentation: { type: Integer, desc: 'Company number', param_type: 'body' }
          expose :name, documentation: { type: String, desc: 'Company Name' }
          expose :environment, documentation: { type: String, desc: 'Test Environment' }
          expose :sites, documentation: { type: Integer, desc: 'Amount of sites' }
          expose :username, documentation: { type: String, desc: 'Username for Dashboard' }
          expose :password, documentation: { type: String, desc: 'Password for Dashboard' }
        end

        class Accounts < Grape::Entity
          expose :accounts, documentation: { type: Entity::Account, is_array: true, param_type: 'body', required: true }
        end
      end
    end
  end

  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_666 do
        desc 'createTestAccount',
             params: TestDefinition::Entity::Accounts.documentation
        post 'create' do
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

  specify do
    expect(subject['definitions']['postIssue666Create']['type']).to eq('object')
  end
end
