require 'spec_helper'

describe 'Grape::Endpoint#path_and_definitions' do
  let(:api) do
    item = Class.new(Grape::API) do
      version 'v1', using: :path

      resource :item do
        get '/'
      end
    end

    Class.new(Grape::API) do
      mount item
      add_swagger_documentation add_version: true
    end
  end

  let(:options) { { add_version: true } }
  let(:target_routes) { api.combined_namespace_routes }

  subject { api.endpoints[0].path_and_definition_objects(target_routes, options) }

  it 'is returning a versioned path' do
    expect(subject[0].keys[0]).to eq '/v1/item'
  end

  it 'tags the endpoint with the resource name' do
    pending 'BUG: This is set to the first part of the path'
    expect(subject.first['/v1/item'][:get][:tags]).to eq ['items']
  end
end
