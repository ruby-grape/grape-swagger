# frozen_string_literal: true

require 'spec_helper'

describe '#605 root route documentation' do
  let(:app) do
    Class.new(Grape::API) do
      get do
        { message: 'hello world' }
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)['paths']
  end

  specify { expect(app.combined_routes.keys).to include '/' }
  specify { expect(subject.keys).to include '/' }
end
