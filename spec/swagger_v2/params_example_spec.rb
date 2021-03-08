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

      get '/endpoint_with_examples' do
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

    specify do
      expect(subject['paths']['/endpoint_with_examples']['get']['parameters']).to eql(
        [
          { 'in' => 'query', 'name' => 'id', 'type' => 'integer', 'example' => 123, 'format' => 'int32', 'required' => true },
          { 'in' => 'query', 'name' => 'name', 'type' => 'string', 'example' => 'Person', 'required' => false },
          { 'in' => 'query', 'name' => 'obj', 'type' => 'Object', 'example' => { 'foo' => 'bar' }, 'required' => false }
        ]
      )
    end
  end
end
