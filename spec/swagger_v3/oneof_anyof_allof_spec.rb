# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.0 oneOf, anyOf, allOf support' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module Entities
      class Cat < OpenStruct
        class << self
          def documentation
            {
              id: { type: Integer, desc: 'Cat ID' },
              name: { type: String, desc: 'Cat name' },
              meow: { type: String, desc: 'Cat sound' }
            }
          end
        end
      end

      class Dog < OpenStruct
        class << self
          def documentation
            {
              id: { type: Integer, desc: 'Dog ID' },
              name: { type: String, desc: 'Dog name' },
              bark: { type: String, desc: 'Dog sound' }
            }
          end
        end
      end

      class Bird < OpenStruct
        class << self
          def documentation
            {
              id: { type: Integer, desc: 'Bird ID' },
              name: { type: String, desc: 'Bird name' },
              tweet: { type: String, desc: 'Bird sound' }
            }
          end
        end
      end
    end
  end

  def app
    Class.new(Grape::API) do
      format :json

      desc 'Get a pet with oneOf'
      params do
        requires :pet, documentation: { type: 'oneOf', values: [Entities::Cat, Entities::Dog] }
      end
      get '/pet_oneof' do
        { status: 'success' }
      end

      desc 'Get a pet with anyOf'
      params do
        requires :pet, documentation: { type: 'anyOf', values: [Entities::Cat, Entities::Dog, Entities::Bird] }
      end
      get '/pet_anyof' do
        { status: 'success' }
      end

      desc 'Get a pet with allOf'
      params do
        requires :pet, documentation: { type: 'allOf', values: [Entities::Cat, Entities::Dog] }
      end
      get '/pet_allof' do
        { status: 'success' }
      end

      add_swagger_documentation
    end
  end

  describe 'oneOf support' do
    subject do
      get '/swagger_doc/pet_oneof'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/pet_oneof']['get']['parameters'].first['schema']).to include('oneOf')
      expect(subject['paths']['/pet_oneof']['get']['parameters'].first['schema']['oneOf']).to be_an(Array)
      expect(subject['paths']['/pet_oneof']['get']['parameters'].first['schema']['oneOf'].length).to eq(2)
      expect(subject['paths']['/pet_oneof']['get']['parameters'].first['schema']['oneOf'][0]['$ref']).to eq('#/components/schemas/Cat')
      expect(subject['paths']['/pet_oneof']['get']['parameters'].first['schema']['oneOf'][1]['$ref']).to eq('#/components/schemas/Dog')
    end
  end

  describe 'anyOf support' do
    subject do
      get '/swagger_doc/pet_anyof'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/pet_anyof']['get']['parameters'].first['schema']).to include('anyOf')
      expect(subject['paths']['/pet_anyof']['get']['parameters'].first['schema']['anyOf']).to be_an(Array)
      expect(subject['paths']['/pet_anyof']['get']['parameters'].first['schema']['anyOf'].length).to eq(3)
      expect(subject['paths']['/pet_anyof']['get']['parameters'].first['schema']['anyOf'][0]['$ref']).to eq('#/components/schemas/Cat')
      expect(subject['paths']['/pet_anyof']['get']['parameters'].first['schema']['anyOf'][1]['$ref']).to eq('#/components/schemas/Dog')
      expect(subject['paths']['/pet_anyof']['get']['parameters'].first['schema']['anyOf'][2]['$ref']).to eq('#/components/schemas/Bird')
    end
  end

  describe 'allOf support' do
    subject do
      get '/swagger_doc/pet_allof'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/pet_allof']['get']['parameters'].first['schema']).to include('allOf')
      expect(subject['paths']['/pet_allof']['get']['parameters'].first['schema']['allOf']).to be_an(Array)
      expect(subject['paths']['/pet_allof']['get']['parameters'].first['schema']['allOf'].length).to eq(2)
      expect(subject['paths']['/pet_allof']['get']['parameters'].first['schema']['allOf'][0]['$ref']).to eq('#/components/schemas/Cat')
      expect(subject['paths']['/pet_allof']['get']['parameters'].first['schema']['allOf'][1]['$ref']).to eq('#/components/schemas/Dog')
    end
  end
end 