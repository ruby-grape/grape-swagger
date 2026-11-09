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

      params do
        optional :dns_servers, type: [String], default: %w[8.8.8.8 8.8.4.4]
      end
      desc 'form', consumes: ['application/x-www-form-urlencoded']
      post '/form' do
        {}
      end

      params do
        optional :dns_servers, type: [String], default: []
      end
      get '/empty' do
        {}
      end

      params do
        optional :dns_servers, type: [String], default: 'z'
      end
      get '/scalar' do
        {}
      end

      params do
        optional :dns_servers, type: [String], default: 'z'
      end
      post '/scalar_body' do
        {}
      end

      params do
        optional :things, type: [JSON], default: [{ 'a' => 1 }] do
          optional :a, type: Integer
        end
      end
      post '/json' do
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

  it 'puts the default on the array for a formData parameter' do
    expect(subject['paths']['/form']['post']['parameters']).to eql(
      [
        { 'in' => 'formData', 'name' => 'dns_servers', 'type' => 'array', 'items' => { 'type' => 'string' },
          'default' => %w[8.8.8.8 8.8.4.4], 'required' => false }
      ]
    )
  end

  it 'emits an empty array default on the array' do
    expect(subject['paths']['/empty']['get']['parameters']).to eql(
      [
        { 'in' => 'query', 'name' => 'dns_servers', 'type' => 'array', 'items' => { 'type' => 'string' },
          'default' => [], 'required' => false }
      ]
    )
  end

  it 'keeps a scalar default of an array parameter in items' do
    expect(subject['paths']['/scalar']['get']['parameters']).to eql(
      [
        { 'in' => 'query', 'name' => 'dns_servers', 'type' => 'array',
          'items' => { 'type' => 'string', 'default' => 'z' }, 'required' => false }
      ]
    )
  end

  it 'keeps a scalar default of an array body property in items' do
    expect(subject['definitions']['postScalarBody']['properties']['dns_servers']).to eql(
      'type' => 'array', 'items' => { 'type' => 'string', 'default' => 'z' }
    )
  end

  it 'puts the default of an array of nested objects on the array property' do
    expect(subject['definitions']['postJson']['properties']['things']).to eql(
      'type' => 'array',
      'items' => { 'type' => 'object', 'properties' => { 'a' => { 'type' => 'integer', 'format' => 'int32' } } },
      'default' => [{ 'a' => 1 }]
    )
  end
end
