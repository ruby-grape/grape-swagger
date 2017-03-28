# frozen_string_literal: true

require 'spec_helper'

describe 'additional parameter settings' do
  before :all do
    module TheApi
      class RequestParamFix < Grape::API
        resource :bookings do
          desc 'Update booking'
          params do
            optional :name, type: String
          end
          put ':id' do
            { 'declared_params' => declared(params) }
          end

          desc 'Get booking details'
          get ':id' do
            { 'declared_params' => declared(params) }
          end

          desc 'Get booking details by access_number'
          get '/conf/:access_number' do
            { 'declared_params' => declared(params) }
          end

          desc 'Remove booking'
          delete ':id' do
            { 'declared_params' => declared(params) }
          end
        end

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::RequestParamFix
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  specify do
    expect(subject['paths']['/bookings/{id}']['put']['parameters'].sort_by { |p| p['name'] }).to eql(
      [
        { 'in' => 'path', 'name' => 'id', 'type' => 'integer', 'format' => 'int32', 'required' => true },
        { 'in' => 'formData', 'name' => 'name', 'type' => 'string', 'required' => false }
      ]
    )
  end

  specify do
    expect(subject['paths']['/bookings/{id}']['get']['parameters']).to eql(
      [
        { 'in' => 'path', 'name' => 'id', 'type' => 'integer', 'format' => 'int32', 'required' => true }
      ]
    )
  end

  specify do
    expect(subject['paths']['/bookings/{id}']['delete']['parameters']).to eql(
      [
        { 'in' => 'path', 'name' => 'id', 'type' => 'integer', 'format' => 'int32', 'required' => true }
      ]
    )
  end
end
