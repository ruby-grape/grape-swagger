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

      class EntityWithExampleTypeField < Grape::Entity
        def self.documentation
          {
            example: { type: 'admin', desc: 'Administrator', name: 'Jane' }
          }
        end

        expose :type, documentation: { type: String, desc: 'Type' }
        expose :desc, documentation: { type: String, desc: 'Description' }
        expose :name, documentation: { type: String, desc: 'Name' }
      end

      class EntityWithoutDocumentation < Grape::Entity
        expose :id, documentation: { type: Integer, desc: 'ID' }
      end

      class EntityWithFieldLevelDocumentation < Grape::Entity
        expose :desc, documentation: { type: String, desc: 'Description field' }
        expose :example, documentation: { type: String, desc: 'Example field' }
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

        desc 'Returns entity with example type field',
             entity: Entities::EntityWithExampleTypeField
        get '/with-example-type-field' do
          { type: 'admin', desc: 'Administrator', name: 'Jane' }
        end

        desc 'Returns entity without documentation method',
             entity: Entities::EntityWithoutDocumentation
        get '/without-documentation' do
          { id: 1 }
        end

        desc 'Returns entity with field-level documentation',
             entity: Entities::EntityWithFieldLevelDocumentation
        get '/with-field-level-documentation' do
          { desc: 'Description', example: 'Example' }
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

      it 'does not use field documentation as a custom description' do
        expect(subject['definitions']['EntityWithFieldLevelDocumentation']['description'])
          .to eq('EntityWithFieldLevelDocumentation model')
      end
    end

    context 'with custom example' do
      it 'uses custom example from documentation method' do
        expect(subject['definitions']['EntityWithCustomDocumentation']['example'])
          .to eq({ 'id' => 123, 'name' => 'Example Name' })
      end

      it 'uses custom example with type and desc fields' do
        expect(subject['definitions']['EntityWithExampleTypeField']['example'])
          .to eq({ 'type' => 'admin', 'desc' => 'Administrator', 'name' => 'Jane' })
      end

      it 'does not include example when not provided' do
        expect(subject['definitions']['EntityWithDescriptionOnly']).not_to have_key('example')
      end

      it 'does not include example when no documentation method' do
        expect(subject['definitions']['EntityWithoutDocumentation']).not_to have_key('example')
      end

      it 'does not use field documentation as a custom example' do
        expect(subject['definitions']['EntityWithFieldLevelDocumentation']).not_to have_key('example')
      end
    end

    context 'with schema properties' do
      it 'includes documented fields when custom model documentation is defined' do
        expect(subject['definitions']['EntityWithCustomDocumentation']['properties'])
          .to eq(
            'id' => { 'type' => 'integer', 'format' => 'int32', 'description' => 'ID' },
            'name' => { 'type' => 'string', 'description' => 'Name' }
          )
      end
    end
  end
end
