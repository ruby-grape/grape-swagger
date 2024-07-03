# frozen_string_literal: true

require 'spec_helper'

describe 'Param example' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :id, type: Integer, documentation: { example: 123 }
        optional :name, type: String, documentation: { example: 'Person' }
        optional :obj, type: 'Object', documentation: { example: { 'foo' => 'bar' } }
      end

      post '/endpoint_with_examples' do
        { 'declared_params' => declared(params) }
      end

      add_swagger_documentation
    end
  end

  describe 'documentation with parameter examples' do
    subject do
      get '/swagger_doc/endpoint_with_examples'
      JSON.parse(last_response.body)
    end

    let(:parameters) { subject['definitions']['postEndpointWithExamples']['properties'] }

    specify do
      expect(parameters).to eql(
        { 'id' => { 'type' => 'integer', 'format' => 'int32', 'example' => 123 }, 'name' => { 'type' => 'string', 'example' => 'Person' }, 'obj' => { 'type' => 'Object', 'example' => { 'foo' => 'bar' } } }
      )
    end
  end
end
