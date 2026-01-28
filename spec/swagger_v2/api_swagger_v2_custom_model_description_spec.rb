# frozen_string_literal: true

require 'spec_helper'

describe 'custom model documentation' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module Entities
      class EntityWithCustomDocumentation < Grape::Entity
        def self.documentation
          {
            desc: 'A custom description for this entity',
            example: { id: 123, name: 'Example Name' }
          }
        end

        expose :id, documentation: { type: Integer, desc: 'ID' }
        expose :name, documentation: { type: String, desc: 'Name' }
      end

      class EntityWithDescriptionOnly < Grape::Entity
        def self.documentation
          { desc: 'Description without example' }
        end

        expose :id, documentation: { type: Integer, desc: 'ID' }
      end

      class EntityWithoutDocumentation < Grape::Entity
        expose :id, documentation: { type: Integer, desc: 'ID' }
      end
    end

    module TheApi
      class CustomModelDocumentationApi < Grape::API
        format :json

        desc 'Returns entity with custom documentation',
             entity: Entities::EntityWithCustomDocumentation
        get '/with-custom-documentation' do
          { id: 1, name: 'Test' }
        end

        desc 'Returns entity with description only',
             entity: Entities::EntityWithDescriptionOnly
        get '/with-description-only' do
          { id: 1 }
        end

        desc 'Returns entity without documentation method',
             entity: Entities::EntityWithoutDocumentation
        get '/without-documentation' do
          { id: 1 }
        end

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::CustomModelDocumentationApi
  end

  describe 'model definitions' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    context 'with custom description' do
      it 'uses custom description from documentation method' do
        expect(subject['definitions']['EntityWithCustomDocumentation']['description'])
          .to eq('A custom description for this entity')
      end

      it 'falls back to default description when no documentation method' do
        expect(subject['definitions']['EntityWithoutDocumentation']['description'])
          .to eq('EntityWithoutDocumentation model')
      end
    end

    context 'with custom example' do
      it 'uses custom example from documentation method' do
        expect(subject['definitions']['EntityWithCustomDocumentation']['example'])
          .to eq({ 'id' => 123, 'name' => 'Example Name' })
      end

      it 'does not include example when not provided' do
        expect(subject['definitions']['EntityWithDescriptionOnly']['example']).to be_nil
      end

      it 'does not include example when no documentation method' do
        expect(subject['definitions']['EntityWithoutDocumentation']['example']).to be_nil
      end
    end
  end
end
