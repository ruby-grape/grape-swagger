require 'spec_helper'

describe 'Array params with at_least_one_of having custom message' do
  include_context "the api entities"

  before :all do
    module TheApi
      class ArrayApi < Grape::API
        # using `:param_type`
        desc 'full set of request param types',
          success: TheApi::Entities::UseResponse
        params do
          requires :my_top_arr, type: Array, allow_blank: false do
            optional :my_elem1,
                     type: Float
            optional :my_elem2,
                     type: String
            at_least_one_of :my_top_arr,
                            :my_elem2,
                            message: 'is missing'
          end
        end

        get '/defined_param_type' do
          { "declared_params" => declared(params) }
        end
        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::ArrayApi
  end

  describe 'defined param types' do
    let(:expected_response) do
      [
        {
          "description" => nil,
                   "in" => "formData",
                "items" => {
            "type" => "float"
          },
                 "name" => "my_top_arr[][my_elem1]",
             "required" => false,
                 "type" => "array"
        },
        {
          "description" => nil,
                   "in" => "formData",
                "items" => {
            "type" => "string"
          },
                 "name" => "my_top_arr[][my_elem2]",
             "required" => false,
                 "type" => "array"
        },
        {
          "description" => nil,
                   "in" => "formData",
                "items" => {
            "type" => "string"
          },
                 "name" => "my_top_arr[][my_top_arr]",
             "required" => false,
                 "type" => "array"
        }
      ]
    end
    subject do
      get '/swagger_doc/defined_param_type'
      JSON.parse(last_response.body)
    end

    specify do
      params_json = subject['paths']['/defined_param_type']['get']['parameters']
      expect(params_json).to eql(expected_response)
    end
  end
end