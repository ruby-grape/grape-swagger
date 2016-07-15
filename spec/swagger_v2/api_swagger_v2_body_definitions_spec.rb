require 'spec_helper'

describe 'body parameter definitions' do
  before :all do
    module TheBodyApi
      class Endpoint < Grape::API
        resource :endpoint do
          desc 'The endpoint' do
            params body_param: { type: String, desc: 'param', required: false, documentation: { in: 'body' } }
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

  context 'a definition is generated for the endpoints parameters' do
    specify do
      expect(subject['definitions']['postEndpoint']['properties']).to eql(
        'body_param' => { 'type' => 'string', 'description' => 'param' }
      )
    end
  end
end
