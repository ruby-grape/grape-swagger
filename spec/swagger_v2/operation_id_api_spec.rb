# frozen_string_literal: true

require 'spec_helper'

describe 'an operation id api' do
  def app
    Class.new(Grape::API) do
      version '0.1'

      desc 'Show this endpoint'
      get '/simple_opp' do
        { foo: 'bar' }
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/0.1/swagger_doc.json'
    JSON.parse(last_response.body)
  end

  it 'uses build name as operationId' do
    expect(subject['paths']['/0.1/simple_opp']['get']['operationId']).to eql('get01SimpleOpp')
  end
end
