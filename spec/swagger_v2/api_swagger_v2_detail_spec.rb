# frozen_string_literal: true

require 'spec_helper'

def details
  <<-DETAILS
    # Burgers in Heaven

    > A burger doesn't come for free

    If you want to reserve a burger in heaven, you have to do
    some crazy stuff on earth.

    ```
    def do_good
    puts 'help people'
    end
    ```

    * _Will go to Heaven:_ Probably
    * _Will go to Hell:_ Probably not
  DETAILS
end

describe 'details' do
  describe 'take deatils as it is' do
    include_context "#{MODEL_PARSER} swagger example"

    before :all do
      module TheApi
        class DetailApi < Grape::API
          format :json

          desc 'This returns something',
               detail: 'detailed description of the route',
               entity: Entities::UseResponse,
               failure: [{ code: 400, model: Entities::ApiError }]
          get '/use_detail' do
            { 'declared_params' => declared(params) }
          end

          desc 'This returns something' do
            detail 'detailed description of the route inside the `desc` block'
            entity Entities::UseResponse
            failure [{ code: 400, model: Entities::ApiError }]
          end
          get '/use_detail_block' do
            { 'declared_params' => declared(params) }
          end

          add_swagger_documentation
        end
      end
    end

    def app
      TheApi::DetailApi
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/use_detail']['get']).to include('summary')
      expect(subject['paths']['/use_detail']['get']['summary']).to eql 'This returns something'
      expect(subject['paths']['/use_detail']['get']).to include('description')
      expect(subject['paths']['/use_detail']['get']['description']).to eql 'detailed description of the route'
    end

    specify do
      expect(subject['paths']['/use_detail_block']['get']).to include('summary')
      expect(subject['paths']['/use_detail_block']['get']['summary']).to eql 'This returns something'
      expect(subject['paths']['/use_detail_block']['get']).to include('description')
      expect(subject['paths']['/use_detail_block']['get']['description']).to eql 'detailed description of the route inside the `desc` block'
    end
  end
end
