# frozen_string_literal: true

require 'spec_helper'

describe 'deprecated endpoint' do
  def app
    Class.new(Grape::API) do
      desc 'Deprecated endpoint', deprecated: true
      get '/foobar' do
        { foo: 'bar' }
      end

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc.json'
    JSON.parse(last_response.body)
  end

  it 'includes the deprecated field' do
    expect(subject['paths']['/foobar']['get']['deprecated']).to eql(true)
  end
end
