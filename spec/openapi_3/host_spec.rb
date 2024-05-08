# frozen_string_literal: true

require 'spec_helper'

describe 'host in the swagger_doc' do
  before :all do
    module TheApi
      class EmptyApi < Grape::API
        format :json

        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end

        add_swagger_documentation openapi_version: '3.0'
      end
    end
  end

  def app
    TheApi::EmptyApi
  end

  describe 'host should include port' do
    subject do
      get 'http://example.com:8080/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['servers'].first['url']).to eq 'http://example.com:8080'
    end
  end

  describe 'respect X-Forwarded-Host over Host header' do
    subject do
      header 'Host', 'dummy.example.com'
      header 'X-Forwarded-Host', 'real.example.com'
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['servers'].first['url']).to eq 'http://real.example.com'
    end
  end
end
