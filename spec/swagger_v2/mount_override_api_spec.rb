# frozen_string_literal: true

require 'spec_helper'

describe 'mount override api' do
  def app
    old_api = Class.new(Grape::API) do
      desc 'old endpoint', success: { code: 200, message: 'old message' }
      params do
        optional :param, type: Integer, desc: 'old param'
      end
      get do
        'old'
      end
    end

    new_api = Class.new(Grape::API) do
      desc 'new endpoint', success: { code: 200, message: 'new message' }
      params do
        optional :param, type: String, desc: 'new param'
      end
      get do
        'new'
      end
    end

    Class.new(Grape::API) do
      mount new_api
      mount old_api

      add_swagger_documentation format: :json
    end
  end

  context 'actual api request' do
    subject do
      get '/'
      last_response.body
    end

    it 'returns data from new endpoint' do
      is_expected.to eq 'new'
    end
  end

  context 'api documentation' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)['paths']['/']['get']
    end

    it 'shows documentation from new endpoint' do
      expect(subject['parameters'][0]['description']).to eql('new param')
      expect(subject['parameters'][0]['type']).to eql('string')
      expect(subject['responses']['200']['description']).to eql('new message')
    end
  end
end
