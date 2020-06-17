# frozen_string_literal: true

require 'spec_helper'

describe '#427 nested entity given as string' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_427 do
        module Permission
          class WithoutRole < Grape::Entity
            expose :id
            expose :description
          end
        end

        class RoleEntity < Grape::Entity
          expose :id
          expose :description
          expose :role
          expose :permissions, using: 'Permission::WithoutRole'
        end
        desc 'Get a list of roles',
             success: RoleEntity
        get '/' do
          present [], with: RoleEntity
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)['definitions']
  end

  specify { expect(subject.keys).to include 'RoleEntity', 'Permission_WithoutRole' }
end
