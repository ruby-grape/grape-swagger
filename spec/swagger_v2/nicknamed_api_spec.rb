# frozen_string_literal: true

require 'spec_helper'

describe 'a nicknamed mounted api' do
  def app
    Class.new(Grape::API) do
      desc 'Show this endpoint', nickname: 'simple'
      get '/simple' do
        { foo: 'bar' }
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc.json'
    JSON.parse(last_response.body)
  end

  it 'uses the nickname as the operationId' do
    expect(subject['paths']['/simple']['get']['operationId']).to eql('simple')
  end
end
