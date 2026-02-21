# frozen_string_literal: true

require 'spec_helper'

describe '#878 handle optional path segments' do
  let(:app) do
    Class.new(Grape::API) do
      resource :books do
        get 'page(/one)(/:two)/three' do
          { message: 'hello world' }
        end
      end

      add_swagger_documentation
    end
  end
  let(:parameters) { subject['paths']['/books/page/{two}/three']['get']['parameters'] }

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  specify do
    section_param = parameters.find { |param| param['name'] == 'two' }
    expect(section_param['in']).to eq 'path'
    expect(subject['paths'].keys).to eq ['/books/page/three', '/books/page/{two}/three', '/books/page/one/three', '/books/page/one/{two}/three']
  end
end
