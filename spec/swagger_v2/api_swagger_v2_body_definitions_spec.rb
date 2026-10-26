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

  %i[post put patch].each do |request_method|
    context "with length limits on #{request_method.to_s.upcase} body parameters" do
      def app
        request_method = http_method
        Class.new(Grape::API) do
          format :json

          params do
            requires :name, type: String, length: { min: 1, max: 50 }
            requires :tags, type: Array[String], length: { min: 0, max: 3 }
            optional :unlimited_name, type: String
            optional :unlimited_tags, type: Array[String]
            optional :details, type: Hash do
              optional :name, type: String, length: { min: 0, max: 20 }
              optional :tags, type: Array[String], length: { min: 1, max: 2 }
            end
          end
          public_send(request_method, :things) { { message: 'hi' } }

          add_swagger_documentation
        end
      end

      let(:http_method) { request_method }
      let(:properties) do
        parameter = subject.fetch('paths').fetch('/things').fetch(http_method.to_s).fetch('parameters').first
        definition = parameter.fetch('schema').fetch('$ref').split('/').last
        subject.fetch('definitions').fetch(definition).fetch('properties')
      end

      it 'preserves string length limits' do
        expect(properties.fetch('name')).to eq('type' => 'string', 'minLength' => 1, 'maxLength' => 50)
      end

      it 'preserves array item limits on the array schema' do
        expect(properties.fetch('tags')).to eq(
          'type' => 'array', 'items' => { 'type' => 'string' }, 'minItems' => 0, 'maxItems' => 3
        )
      end

      it 'preserves length limits within nested objects' do
        expect(properties.fetch('details').fetch('properties')).to include(
          'name' => { 'type' => 'string', 'minLength' => 0, 'maxLength' => 20 },
          'tags' => { 'type' => 'array', 'items' => { 'type' => 'string' }, 'minItems' => 1, 'maxItems' => 2 }
        )
      end

      it 'leaves unconstrained properties unchanged' do
        expect(properties.fetch('unlimited_name')).to eq('type' => 'string')
        expect(properties.fetch('unlimited_tags')).to eq('type' => 'array', 'items' => { 'type' => 'string' })
      end
    end
  end
end
