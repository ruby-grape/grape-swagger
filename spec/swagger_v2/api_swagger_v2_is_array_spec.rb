# frozen_string_literal: true

require 'spec_helper'

describe 'desc is_array option' do
  let(:app) do
    class User < Grape::Entity
      expose :name
    end
    Class.new(Grape::API) do
      namespace :hash do
        desc 'Get users',
             success: User,
             is_array: true
        get {}
      end
      namespace :block do
        desc 'Get users' do
          success User
          is_array true
        end
        get {}
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  def type_in_success_response_schema(style)
    subject['paths']["/#{style}"]['get']['responses']['200']['schema']['type']
  end

  context 'in hash style' do
    it { expect(type_in_success_response_schema('hash')).to eq 'array' }
  end

  context 'in block style' do
    it { expect(type_in_success_response_schema('block')).to eq 'array' }
  end
end
