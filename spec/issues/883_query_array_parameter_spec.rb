# frozen_string_literal: true

require 'spec_helper'

describe '#883 Group Params as Array' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_883 do
        params do
          requires :array_of_string, type: [String]
          requires :array_of_integer, type: [Integer]
        end
        get '/get_primitive_array_parameters' do
          'accepts array query parameters of primitive value types'
        end

        params do
          requires :array_of, type: Array, documentation: { type: 'link', is_array: true }
        end
        get '/get_object_array_parameters' do
          'does not accept array query parameters of object value types'
        end
      end
      add_swagger_documentation
    end
  end

  describe 'retrieves the documentation for typed group range parameters' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/issue_883/get_primitive_array_parameters']['get']['parameters']).to eql(
        [
          {'in'=>'query', 'name'=>'array_of_string', 'type'=>'array', 'items'=>{'type'=>'string'}, 'required'=>true},
          {'in'=>'query', 'name'=>'array_of_integer', 'type'=>'array', 'items'=>{'type'=>'integer', 'format'=>'int32'}, 'required'=>true}
        ]
      )
      expect(subject['paths']['/issue_883/get_object_array_parameters']['get']['parameters']).to eql(
        [{'in'=>'formData', 'items'=>{'type'=>'string'}, 'name'=>'array_of', 'required'=>true, 'type'=>'array'}]
      )
    end
  end
end