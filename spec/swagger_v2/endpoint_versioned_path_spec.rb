require 'spec_helper'

describe 'Grape::Endpoint#path_and_definitions' do
  before do
    module API
      module V1
        class Item < Grape::API
          version 'v1', using: :path

          resource :item do
            get '/'
          end
        end
      end

      class Root < Grape::API
        mount API::V1::Item
        add_swagger_documentation add_version: true
      end
    end

    @options = { add_version: true }
    @target_routes = API::Root.combined_namespace_routes
  end

  it 'is returning a versioned path' do
    expect(API::V1::Item.endpoints[0]
      .path_and_definition_objects(@target_routes, @options)[0].keys[0]).to eql '/v1/item'
  end
end
