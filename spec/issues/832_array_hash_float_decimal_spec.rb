# frozen_string_literal: true

require 'spec_helper'

describe '#832 array of objects with nested Float/BigDecimal fields' do
  let(:app) do
    Class.new(Grape::API) do
      resource :issue_832 do
        params do
          requires :array_param, type: Array do
            requires :float_param, type: Float
            requires :big_decimal_param, type: BigDecimal
            requires :object_param, type: Hash do
              requires :float_param, type: Float
              requires :big_decimal_param, type: BigDecimal
              requires :object_param, type: Hash do
                requires :float_param, type: Float
                requires :big_decimal_param, type: BigDecimal
                requires :array_param, type: Array do
                  requires :integer_param, type: Integer
                end
              end
            end
          end
        end
        post do
          {  message: 'hello world' }
        end
      end

      add_swagger_documentation
    end
  end
  let(:parameters) { subject['paths']['/issue_832']['post']['parameters'] }

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  specify do
    expect(parameters).to eql(
      [
        {
          'in' => 'formData',
          'name' => 'array_param[float_param]',
          'type' => 'array',
          'required' => true,
          'items' => {
            'type' => 'number',
            'format' => 'float'
          }
        }, {
          'in' => 'formData',
          'name' => 'array_param[big_decimal_param]',
          'type' => 'array',
          'required' => true,
          'items' => {
            'type' => 'number',
            'format' => 'double'
          }
        }, {
          'in' => 'formData',
          'name' => 'array_param[object_param][float_param]',
          'type' => 'array',
          'required' => true,
          'items' => {
            'type' => 'number',
            'format' => 'float'
          }
        }, {
          'in' => 'formData',
          'name' => 'array_param[object_param][big_decimal_param]',
          'type' => 'array',
          'required' => true,
          'items' => {
            'type' => 'number',
            'format' => 'double'
          }
        }, {
          'in' => 'formData',
          'name' => 'array_param[object_param][object_param][float_param]',
          'type' => 'array',
          'required' => true,
          'items' => {
            'type' => 'number',
            'format' => 'float'
          }
        }, {
          'in' => 'formData',
          'name' => 'array_param[object_param][object_param][big_decimal_param]',
          'type' => 'array',
          'required' => true,
          'items' => {
            'type' => 'number',
            'format' => 'double'
          }
        }, {
          'in' => 'formData',
          'name' => 'array_param[object_param][object_param][array_param][integer_param]',
          'type' => 'array',
          'required' => true,
          'items' => {
            'type' => 'integer',
            'format' => 'int32'
          }
        }
      ]
    )
  end
end
