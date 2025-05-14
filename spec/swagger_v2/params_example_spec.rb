# frozen_string_literal: true

require 'spec_helper'

describe 'Param example' do
  def app
    Class.new(Grape::API) do
      format :json

      helpers do
        params :common_params do
          requires :id, type: Integer, documentation: { example: 123 }
          optional :name, type: String, documentation: { example: 'Person' }
          optional :obj, type: 'Object', documentation: { example: { 'foo' => 'bar' } }
        end
      end

      params do
        use :common_params
      end
      get '/endpoint_with_examples/:id' do
        { 'declared_params' => declared(params) }
      end

      params do
        use :common_params
      end
      post '/endpoint_with_examples/:id' do
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

    describe 'examples for non-body parameters ' do
      specify do
        expect(subject['paths']['/endpoint_with_examples/{id}']['get']['parameters']).to eql(
          [
            { 'in' => 'path', 'name' => 'id', 'type' => 'integer', 'x-example' => 123, 'format' => 'int32', 'required' => true },
            { 'in' => 'query', 'name' => 'name', 'type' => 'string', 'x-example' => 'Person', 'required' => false },
            { 'in' => 'query', 'name' => 'obj', 'type' => 'Object', 'x-example' => { 'foo' => 'bar' }, 'required' => false }
          ]
        )
      end
    end

    describe 'examples for body parameters' do
      specify do
        expect(subject['paths']['/endpoint_with_examples/{id}']['post']['parameters']).to eql(
          [
            { 'in' => 'path', 'name' => 'id', 'type' => 'integer', 'x-example' => 123, 'format' => 'int32', 'required' => true },
            { 'in' => 'body', 'name' => 'postEndpointWithExamplesId', 'schema' => { '$ref' => '#/definitions/postEndpointWithExamplesId' }, 'required' => true }
          ]
        )
        expect(subject['definitions']['postEndpointWithExamplesId']).to eql(
          'type' => 'object',
          'properties' => {
            'name' => { 'type' => 'string', 'example' => 'Person' },
            'obj' => { 'type' => 'Object', 'example' => { 'foo' => 'bar' } }
          }
        )
      end
    end
  end
end
