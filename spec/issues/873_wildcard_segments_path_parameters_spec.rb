# frozen_string_literal: true

require 'spec_helper'

describe '#873 detect wildcard segments as path parameters' do
  let(:app) do
    Class.new(Grape::API) do
      resource :books do
        get '*section/:title' do
          { message: 'hello world' }
        end
      end

      add_swagger_documentation
    end
  end
  let(:parameters) { subject['paths']['/books/{section}/{title}']['get']['parameters'] }

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  specify do
    section_param = parameters.find { |param| param['name'] == 'section' }
    expect(section_param['in']).to eq 'path'
  end
end
