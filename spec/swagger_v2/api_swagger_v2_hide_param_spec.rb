# frozen_string_literal: true

require 'spec_helper'

describe 'hidden flag enables a single endpoint parameter to be excluded from the documentation' do
  include_context "#{MODEL_PARSER} swagger example"
  before :all do
    module TheApi
      class HideParamsApi < Grape::API
        helpers do
          def resource_owner
            '123'
          end
        end

        namespace :flat_params_endpoint do
          desc 'This is a endpoint with a flat parameter hierarchy'
          params do
            requires :name, type: String, documentation: { desc: 'name' }
            optional :favourite_color, type: String, documentation: { desc: 'I should not be anywhere', hidden: true }
            optional :proc_param, type: String, documentation: { desc: 'I should not be anywhere', hidden: proc { true } }
            optional :proc_with_token, type: String, documentation: { desc: 'I may be somewhere', hidden: proc { false } }
          end

          post do
            { 'declared_params' => declared(params) }
          end
        end

        namespace :nested_params_endpoint do
          desc 'This is a endpoint with a nested parameter hierarchy'
          params do
            optional :name, type: String, documentation: { desc: 'name' }
            optional :hidden_attribute, type: Hash do
              optional :favourite_color, type: String, documentation: { desc: 'I should not be anywhere', hidden: true }
            end

            optional :attributes, type: Hash do
              optional :attribute_1, type: String, documentation: { desc: 'Attribute one' }
              optional :hidden_attribute, type: String, documentation: { desc: 'I should not be anywhere', hidden: true }
            end
          end

          post do
            { 'declared_params' => declared(params) }
          end
        end

        namespace :required_param_endpoint do
          desc 'This endpoint has hidden defined for a required parameter'
          params do
            requires :name, type: String, documentation: { desc: 'name', hidden: true }
          end

          post do
            { 'declared_params' => declared(params) }
          end
        end

        add_swagger_documentation token_owner: 'resource_owner'
      end
    end
  end

  let(:app) { TheApi::HideParamsApi }

  describe 'simple flat parameter hierarchy' do
    subject do
      get '/swagger_doc/flat_params_endpoint'
      JSON.parse(last_response.body)
    end

    it 'ignores parameters that are explicitly hidden' do
      expect(subject['paths']['/flat_params_endpoint']['post']['parameters'].map { |p| p['name'] }).not_to include('favourite_color', 'proc_param')
    end

    it 'allows procs to consult the token_owner' do
      expect(subject['paths']['/flat_params_endpoint']['post']['parameters'].map { |p| p['name'] }).to include('proc_with_token')
    end
  end

  describe 'nested parameter hierarchy' do
    subject do
      get '/swagger_doc/nested_params_endpoint'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/nested_params_endpoint']['post']['parameters'].map { |p| p['name'] }).not_to include(/hidden_attribute/)
    end
  end

  describe 'hidden defined for required parameter' do
    subject do
      get '/swagger_doc/required_param_endpoint'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/required_param_endpoint']['post']['parameters'].map { |p| p['name'] }).to include('name')
    end
  end
end
