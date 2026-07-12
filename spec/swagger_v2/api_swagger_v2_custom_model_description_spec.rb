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

      class EntityWithExampleDescriptionField < Grape::Entity
        def self.documentation
          {
            example: { type: 'string', description: 'Not real example data', format: 'email', in: 'body' }
          }
        end

        expose :type, documentation: { type: String, desc: 'Type' }
      end

      class EntityWithCapitalizedTypeExampleField < Grape::Entity
        def self.documentation
          {
            example: { type: 'String', desc: 'Not real example data' }
          }
        end

        expose :value, documentation: { type: String, desc: 'Value' }
      end

      class EntityWithoutDocumentation < Grape::Entity
        expose :id, documentation: { type: Integer, desc: 'ID' }
      end

      class EntityOnlyReferencedByString < Grape::Entity
        def self.documentation
          { desc: 'Referenced only via a string model name', example: { value: 'ok' } }
        end

        expose :value, documentation: { type: String, desc: 'Value' }
      end

      class EntityWithCallCountingDocumentation < Grape::Entity
        def self.documentation_call_count
          @documentation_call_count ||= 0
        end

        def self.documentation
          @documentation_call_count = documentation_call_count + 1
          { desc: "Description from call #{documentation_call_count}", example: { call: documentation_call_count } }
        end

        expose :call, documentation: { type: Integer, desc: 'Call' }
      end

      class EntityWithRaisingDocumentation < Grape::Entity
        def self.documentation
          raise 'boom'
        end

        expose :id, documentation: { type: Integer, desc: 'ID' }
      end

      class EntityWithFieldLevelDocumentation < Grape::Entity
        expose :desc, documentation: { type: String, desc: 'Description field' }
        expose :example, documentation: { type: String, desc: 'Example field' }
      end

      class EntityWithUntypedExampleDocumentation < Grape::Entity
        expose :example, documentation: { desc: 'Example field' }
      end

      class ModelWithExamplePropertyDocumentation
        def self.documentation
          {
            example: { desc: 'Example field' },
            name: { type: String, desc: 'Name' }
          }
        end

        def self.parse(value)
          value
        end
      end
    end

    class ExamplePropertyDocumentationParser
      def initialize(model, endpoint); end

      def call
        Entities::ModelWithExamplePropertyDocumentation.documentation
      end
    end

    GrapeSwagger.model_parsers.register(ExamplePropertyDocumentationParser, Entities::ModelWithExamplePropertyDocumentation)

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

        desc 'Returns entity with example description field',
             entity: Entities::EntityWithExampleDescriptionField
        get '/with-example-description-field' do
          { type: 'admin' }
        end

        desc 'Returns entity with capitalized string type in example field',
             entity: Entities::EntityWithCapitalizedTypeExampleField
        get '/with-capitalized-type-example-field' do
          { value: 'ok' }
        end

        desc 'Returns entity without documentation method',
             entity: Entities::EntityWithoutDocumentation
        get '/without-documentation' do
          { id: 1 }
        end

        desc 'Returns entity referenced by a string model name',
             failure: [{ code: 400, message: 'Error', model: 'Entities::EntityOnlyReferencedByString' }]
        get '/with-string-model-reference' do
          { value: 'ok' }
        end

        desc 'Returns entity with call-counting documentation',
             entity: Entities::EntityWithCallCountingDocumentation
        get '/with-call-counting-documentation' do
          { call: 1 }
        end

        desc 'Returns entity whose documentation method raises',
             entity: Entities::EntityWithRaisingDocumentation
        get '/with-raising-documentation' do
          { id: 1 }
        end

        desc 'Returns entity with field-level documentation',
             entity: Entities::EntityWithFieldLevelDocumentation
        get '/with-field-level-documentation' do
          { desc: 'Description', example: 'Example' }
        end

        desc 'Returns entity with untyped example documentation',
             entity: Entities::EntityWithUntypedExampleDocumentation
        get '/with-untyped-example-documentation' do
          { example: 'Example' }
        end

        desc 'Returns model with an example property',
             entity: Entities::ModelWithExamplePropertyDocumentation
        get '/with-example-property-documentation' do
          { example: 'Example', name: 'Jane' }
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

      it 'does not use untyped field documentation as a custom example' do
        expect(subject['definitions']['EntityWithUntypedExampleDocumentation']).not_to have_key('example')
      end

      it 'does not use non-entity property documentation as a custom example' do
        expect(subject['definitions']['ModelWithExamplePropertyDocumentation']).not_to have_key('example')
      end

      it 'does not use field documentation with description/format/in keys as a custom example' do
        expect(subject['definitions']['EntityWithExampleDescriptionField']).not_to have_key('example')
      end

      it 'does not use field documentation with a capitalized string type as a custom example' do
        expect(subject['definitions']['EntityWithCapitalizedTypeExampleField']).not_to have_key('example')
      end
    end

    context 'with a model referenced by string' do
      it 'applies custom documentation when the model is referenced by a string class name' do
        expect(subject['definitions']['EntityOnlyReferencedByString']['description'])
          .to eq('Referenced only via a string model name')
        expect(subject['definitions']['EntityOnlyReferencedByString']['example'])
          .to eq({ 'value' => 'ok' })
      end
    end

    context 'with a non-idempotent documentation method' do
      it 'derives description and example from a single documentation invocation' do
        description = subject['definitions']['EntityWithCallCountingDocumentation']['description']
        example = subject['definitions']['EntityWithCallCountingDocumentation']['example']

        expect(description).to eq("Description from call #{example['call']}")
      end
    end

    context 'when the documentation method raises' do
      it 'does not crash swagger doc generation and falls back to the default description' do
        documentation = subject

        expect(last_response.status).to eq(200)
        expect(documentation['definitions']['EntityWithRaisingDocumentation']['description'])
          .to eq('EntityWithRaisingDocumentation model')
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
