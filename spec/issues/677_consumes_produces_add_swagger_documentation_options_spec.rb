# frozen_string_literal: true

require 'spec_helper'

describe '#677 consumes and produces options are included in add_swagger_documentation options' do
  describe 'no override' do
    let(:app) do
      Class.new(Grape::API) do
        resource :accounts do
          route_param :account_number, type: String do
            resource :records do
              route_param :id do
                post do
                  { message: 'hello world' }
                end
              end
            end
          end
        end

        add_swagger_documentation \
          format: :json
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/accounts/{account_number}/records/{id}']['post']['produces']).to eq ['application/json']
      expect(subject['paths']['/accounts/{account_number}/records/{id}']['post']['consumes']).to eq ['application/json']
    end
  end

  describe 'override produces' do
    let(:app) do
      Class.new(Grape::API) do
        resource :accounts do
          route_param :account_number, type: String do
            resource :records do
              route_param :id do
                post do
                  { message: 'hello world' }
                end
              end
            end
          end
        end

        add_swagger_documentation \
          format: :json,
          produces: ['text/plain']
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/accounts/{account_number}/records/{id}']['post']['produces']).to eq ['text/plain']
      expect(subject['paths']['/accounts/{account_number}/records/{id}']['post']['consumes']).to eq ['application/json']
    end
  end

  describe 'override consumes' do
    let(:app) do
      Class.new(Grape::API) do
        resource :accounts do
          route_param :account_number, type: String do
            resource :records do
              route_param :id do
                post do
                  { message: 'hello world' }
                end
              end
            end
          end
        end

        add_swagger_documentation(
          format: :json,
          consumes: ['application/json', 'application/x-www-form-urlencoded']
        )
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/accounts/{account_number}/records/{id}']['post']['produces']).to eq ['application/json']
      expect(subject['paths']['/accounts/{account_number}/records/{id}']['post']['consumes']).to eq ['application/json', 'application/x-www-form-urlencoded']
    end
  end
end
