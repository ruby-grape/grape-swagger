# frozen_string_literal: true

require 'spec_helper'

describe '#950 array default belongs to the array, not its items' do
  let(:app) do
    Class.new(Grape::API) do
      params do
        optional :dns_servers, type: [String], default: %w[8.8.8.8 8.8.4.4]
      end
      get '/query' do
        {}
      end

      params do
        optional :dns_servers, type: [String], default: %w[8.8.8.8 8.8.4.4]
      end
      post '/body' do
        {}
      end

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  it 'puts the default on the array for a query parameter' do
    expect(subject['paths']['/query']['get']['parameters']).to eql(
      [
        { 'in' => 'query', 'name' => 'dns_servers', 'type' => 'array', 'items' => { 'type' => 'string' },
          'default' => %w[8.8.8.8 8.8.4.4], 'required' => false }
      ]
    )
  end

  it 'puts the default on the array property of a body definition' do
    expect(subject['definitions']['postBody']['properties']['dns_servers']).to eql(
      'type' => 'array', 'items' => { 'type' => 'string' }, 'default' => %w[8.8.8.8 8.8.4.4]
    )
  end
end
