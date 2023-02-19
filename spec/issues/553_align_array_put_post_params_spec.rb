# frozen_string_literal: true

require 'spec_helper'

describe '#553 array of type in post/put params' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :in_form_data do
        desc 'create foo' do
          consumes ['application/x-www-form-urlencoded']
        end
        params do
          requires :guid, type: Array[String]
        end
        post do
          # your code goes here
        end

        desc 'put specific foo' do
          consumes ['application/x-www-form-urlencoded']
        end
        params do
          requires :id
          requires :guid, type: Array[String]
        end
        put ':id' do
          # your code goes here
        end
      end

      namespace :in_body do
        desc 'create foo' do
          consumes ['application/x-www-form-urlencoded']
        end
        params do
          requires :guid, type: Array[String], documentation: { param_type: 'body' }
        end
        post do
          # your code goes here
        end

        desc 'put specific foo' do
          consumes ['application/x-www-form-urlencoded']
        end
        params do
          requires :id
          requires :guid, type: Array[String], documentation: { param_type: 'body' }
        end
        put ':id' do
          # your code goes here
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'type for Array specified' do
    describe 'in formData' do
      describe 'post request' do
        let(:params) { subject['paths']['/in_form_data']['post']['parameters'] }

        specify do
          expect(params).to eql([{
            'in' => 'formData',
            'name' => 'guid',
            'type' => 'array',
            'items' => { 'type' => 'string' },
            'required' => true
          }])
        end
      end

      describe 'put request' do
        let(:params) { subject['paths']['/in_form_data/{id}']['put']['parameters'] }

        specify do
          expect(params).to eql(
            [
              {
                'in' => 'path',
                'name' => 'id',
                'type' => 'string',
                'required' => true
              },
              {
                'in' => 'formData',
                'name' => 'guid',
                'type' => 'array',
                'items' => { 'type' => 'string' },
                'required' => true
              }
            ]
          )
        end
      end
    end

    describe 'in body' do
      describe 'post request' do
        let(:params) { subject['paths']['/in_body']['post']['parameters'] }

        specify do
          expect(params).to eql(
            [
              {
                'in' => 'body',
                'name' => 'guid',
                'required' => true,
                'schema' => {
                  'type' => 'array',
                  'items' => { 'type' => 'string' }
                }
              }
            ]
          )
        end
      end

      describe 'put request' do
        let(:params) { subject['paths']['/in_body/{id}']['put']['parameters'] }

        specify do
          expect(params).to eql(
            [
              {
                'in' => 'path',
                'name' => 'id',
                'type' => 'string',
                'required' => true
              },
              {
                'in' => 'body',
                'name' => 'guid',
                'required' => true,
                'schema' => {
                  'type' => 'array',
                  'items' => { 'type' => 'string' }
                }
              }
            ]
          )
        end
      end
    end
  end
end
