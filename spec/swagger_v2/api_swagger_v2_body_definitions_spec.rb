# frozen_string_literal: true

require 'spec_helper'

describe 'body parameter definitions' do
  before :all do
    module TheBodyApi
      class Endpoint < Grape::API
        resource :endpoint do
          desc 'The endpoint' do
            headers XAuthToken: {
              description: 'Valdates your identity',
              required: true
            }
            params body_param: { type: 'String', desc: 'param', documentation: { in: 'body' } },
                   body_type_as_const_param: { type: String, desc: 'string_param', documentation: { in: 'body' } }
          end

          post do
            { 'declared_params' => declared(params) }
          end
        end

        add_swagger_documentation
      end
    end
  end

  def app
    TheBodyApi::Endpoint
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  context 'a definition is generated for the endpoints parameters defined within the desc block' do
    specify do
      expect(subject['definitions']['postEndpoint']['properties']).to eql(
        'body_param' => { 'type' => 'string', 'description' => 'param' },
        'body_type_as_const_param' => { 'type' => 'string', 'description' => 'string_param' }
      )

      expect(subject['paths']['/endpoint']['post']['parameters'].any? { |p| p['name'] == 'XAuthToken' && p['in'] == 'header' }).to eql(true)
    end
  end
end
