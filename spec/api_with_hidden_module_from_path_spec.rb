require 'spec_helper'
require 'byebug'
describe 'Api with "path" versioning and using modules' do
  let(:json_body) { JSON.parse(last_response.body) }

  before :all do
    module Api
      module V1
        class TestResource < Grape::API
          namespace :resources do
            get '/' do
              { bla: 'something' }
            end
          end
        end

        class ModularizedApiWithPathVersioning < Grape::API
          format :json
          version 'v1', using: :path

          mount Api::V1::TestResource

          add_swagger_documentation api_version: 'v1'
        end
        class ModularizedApiWithPathVersioningHidingModule < Grape::API
          format :json
          version 'v1', using: :path

          mount Api::V1::TestResource

          add_swagger_documentation api_version: 'v1', hide_module_from_path: true
        end
      end
    end
  end

  def app_without_hiding
    Api::V1::ModularizedApiWithPathVersioning
  end

  def app_with_hiding
    Api::V1::ModularizedApiWithPathVersioningHidingModule
  end

  context 'when not hiding module from path' do
    let(:app) { app_without_hiding }

    it 'retrieves swagger-documentation on /swagger_doc/resources that contains :resources api path with version' do
      get '/v1/swagger_doc/resources'

      expect(json_body['apis'][0]['path']).to match(%r{/v1/resources})
    end
  end

  context 'when hiding module from path' do
    let(:app) { app_with_hiding }

    it 'retrieves swagger-documentation on /swagger_doc/resources that contains :resources api path without version' do
      get '/v1/swagger_doc/resources'

      expect(json_body['apis'][0]['path']).to match(%r{/resources})
    end
  end
end
