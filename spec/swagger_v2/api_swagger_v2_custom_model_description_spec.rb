# frozen_string_literal: true

require 'spec_helper'

describe 'custom model description' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module Entities
      class EntityWithCustomDescription < Grape::Entity
        def self.documentation
          { desc: 'A custom description for this entity' }
        end

        expose :id, documentation: { type: Integer, desc: 'ID' }
        expose :name, documentation: { type: String, desc: 'Name' }
      end

      class EntityWithoutCustomDescription < Grape::Entity
        expose :id, documentation: { type: Integer, desc: 'ID' }
      end
    end

    module TheApi
      class CustomModelDescriptionApi < Grape::API
        format :json

        desc 'Returns entity with custom description',
             entity: Entities::EntityWithCustomDescription
        get '/with-custom-description' do
          { id: 1, name: 'Test' }
        end

        desc 'Returns entity without custom description',
             entity: Entities::EntityWithoutCustomDescription
        get '/without-custom-description' do
          { id: 1 }
        end

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::CustomModelDescriptionApi
  end

  describe 'model definitions' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'uses custom description from documentation method' do
      expect(subject['definitions']['EntityWithCustomDescription']['description'])
        .to eq('A custom description for this entity')
    end

    it 'falls back to default description when no documentation method' do
      expect(subject['definitions']['EntityWithoutCustomDescription']['description'])
        .to eq('EntityWithoutCustomDescription model')
    end
  end
end
