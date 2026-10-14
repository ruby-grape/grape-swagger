# frozen_string_literal: true

require 'spec_helper'

describe 'OAS 3.0 add_root' do
  before :all do
    module AddRootSpec
      class Thing < Grape::Entity
        expose :name, documentation: { type: String }
      end
    end
  end

  def schema_for(add_root)
    api = Class.new(Grape::API) do
      format :json
      desc 'Thing', success: AddRootSpec::Thing
      get('/thing') { {} }
      add_swagger_documentation openapi_version: '3.0', add_root: add_root
    end
    session = Rack::Test::Session.new(Rack::MockSession.new(api))
    session.get '/swagger_doc'
    JSON.parse(session.last_response.body).dig('paths', '/thing', 'get', 'responses', '200', 'content',
                                               'application/json', 'schema')
  end

  it 'wraps the response under the default root for add_root: true' do
    expect(schema_for(true)['properties'].keys).to eq(['add_root_spec_thing'])
  end

  it 'uses the default root, not the value, for any other truthy add_root' do
    expect(schema_for('custom')['properties'].keys).to eq(['add_root_spec_thing'])
  end

  it 'does not wrap by default' do
    expect(schema_for(false)).to eq('$ref' => '#/components/schemas/AddRootSpec_Thing')
  end
end
