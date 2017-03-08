# frozen_string_literal: true
require 'spec_helper'

describe 'security requirement on endpoint method' do
  def app
    Class.new(Grape::API) do
      desc 'Endpoint with security requirement', security: [oauth_pets: ['read:pets', 'write:pets']]
      get '/with_security' do
        { foo: 'bar' }
      end

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc.json'
    JSON.parse(last_response.body)
  end

  it 'defines the security requirement on the endpoint method' do
    expect(subject['paths']['/with_security']['get']['security']).to eql ['oauth_pets' => ['read:pets', 'write:pets']]
  end
end
