# frozen_string_literal: true

require 'spec_helper'

describe '#532 allow custom format' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_784 do
        params do
          requires :logs, type: String, documentation: { format: 'log', x: { name: 'Log' } }
          optional :phone_number, type: Integer, documentation: { format: 'phone_number', x: { name: 'PhoneNumber' } }
        end

        post do
          present params
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  let(:parameters) { subject['paths']['/issue_784']['post']['parameters'] }

  specify do
    expect(parameters).to eql(
      [
        { 'in' => 'formData', 'name' => 'logs', 'type' => 'string', 'format' => 'log', 'required' => true, 'x-name' => 'Log' },
        { 'in' => 'formData', 'name' => 'phone_number', 'type' => 'integer', 'format' => 'phone_number', 'required' => false, 'x-name' => 'PhoneNumber' }
      ]
    )
  end
end
