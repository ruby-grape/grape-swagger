# frozen_string_literal: true

require 'spec_helper'

describe 'Group Params as Hash' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :required_group, type: Hash do
          requires :required_param_1
          requires :required_param_2
        end
      end
      post '/use_groups' do
        { 'declared_params' => declared(params) }
      end

      params do
        requires :typed_group, type: Hash do
          requires :id, type: Integer, desc: 'integer given'
          requires :name, type: String, desc: 'string given'
          optional :email, type: String, desc: 'email given'
          optional :others, type: Integer, values: [1, 2, 3]
        end
      end
      post '/use_given_type' do
        { 'declared_params' => declared(params) }
      end

      add_swagger_documentation
    end
  end

  describe 'grouped parameters' do
    subject do
      get '/swagger_doc/use_groups'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/use_groups']['post']).to include('parameters')
      expect(subject['paths']['/use_groups']['post']['parameters']).to eql(
        [
          { 'in' => 'formData', 'name' => 'required_group[required_param_1]', 'type' => 'string', 'required' => true },
          { 'in' => 'formData', 'name' => 'required_group[required_param_2]', 'type' => 'string', 'required' => true }
        ]
      )
    end
  end

  describe 'grouped parameters with given type' do
    subject do
      get '/swagger_doc/use_given_type'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/use_given_type']['post']).to include('parameters')
      expect(subject['paths']['/use_given_type']['post']['parameters']).to eql(
        [
          { 'in' => 'formData', 'name' => 'typed_group[id]', 'description' => 'integer given', 'type' => 'integer', 'required' => true, 'format' => 'int32' },
          { 'in' => 'formData', 'name' => 'typed_group[name]', 'description' => 'string given', 'type' => 'string', 'required' => true },
          { 'in' => 'formData', 'name' => 'typed_group[email]', 'description' => 'email given', 'type' => 'string', 'required' => false },
          { 'in' => 'formData', 'name' => 'typed_group[others]', 'type' => 'integer', 'required' => false, 'format' => 'int32', 'enum' => [1, 2, 3] }
        ]
      )
    end
  end
end
