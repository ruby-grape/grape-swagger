# frozen_string_literal: true

require 'spec_helper'

describe 'Default param' do
  def app
    Class.new(Grape::API) do
      format :json

      desc 'Get with default proc value'
      params do
        optional :timestamp, type: String, default: proc { Time.now.utc.iso8601 },
                             desc: 'A timestamp with default value from proc'
        optional :static_value, type: String, default: 'static',
                                desc: 'A parameter with static default value'
      end
      get '/with_default_proc' do
        { timestamp: params[:timestamp], static_value: params[:static_value] }
      end

      add_swagger_documentation
    end
  end

  describe 'swagger documentation' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'resolves the proc to a value for default parameter' do
      parameters = subject['paths']['/with_default_proc']['get']['parameters']

      timestamp_param = parameters.find { |p| p['name'] == 'timestamp' }
      expect(timestamp_param).to be_present
      expect(timestamp_param['default']).to be_present
      # The default value should be a string in ISO8601 format
      expect(timestamp_param['default']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end

    it 'correctly documents static default values' do
      parameters = subject['paths']['/with_default_proc']['get']['parameters']

      static_param = parameters.find { |p| p['name'] == 'static_value' }
      expect(static_param).to be_present
      expect(static_param['default']).to eq('static')
    end
  end
end
