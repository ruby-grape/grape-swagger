# frozen_string_literal: true

describe '#962 polymorphic entity with custom documentation' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_962 do
        module Issue962
          class EmptyEntity < Grape::Entity
          end

          class EntityWithHiddenProperty < Grape::Entity
            expose :hidden_prop, documentation: { hidden: true, desc: 'This property is not exposed.' }
          end

          class EntityWithNestedEmptyEntity < Grape::Entity
            expose :array_of_empty_entities,
                   as: :empty_items,
                   using: Issue962::EmptyEntity,
                   documentation: {
                     is_array: true,
                     desc: 'This is a nested empty entity.'
                   }
            expose :array_of_hidden_entities,
                   as: :hidden_items,
                   using: Issue962::EntityWithHiddenProperty,
                   documentation: {
                     is_array: true,
                     desc: 'This is a nested entity with hidden props'
                   }
          end
        end

        desc 'Get a report',
             success: Issue962::EntityWithNestedEmptyEntity
        get '/' do
          present({ foo: [] }, with: Issue962::EntityWithNestedEmptyEntity)
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  let(:definitions) { subject['definitions'] }
  let(:entity_definition) { definitions['Issue962_EntityWithNestedEmptyEntity'] }
  let(:empty_items_property) { entity_definition['properties']['empty_items'] }
  let(:hidden_items_property) { entity_definition['properties']['hidden_items'] }
  let(:empty_entity_definition) { definitions['Issue962_EmptyEntity'] }
  let(:hidden_entity_definition) { definitions['Issue962_EntityWithHiddenProperty'] }

  specify 'should generate swagger documentation without error' do
    expect { subject }.not_to raise_error
  end

  specify do
    expect(definitions.keys).to include(
      'Issue962_EntityWithNestedEmptyEntity',
      'Issue962_EntityWithHiddenProperty',
      'Issue962_EmptyEntity'
    )
  end

  specify do
    expect(empty_items_property).to eql({
      'type' => 'array',
      'description' => 'This is a nested empty entity.',
      'items' => {
        '$ref' => '#/definitions/Issue962_EmptyEntity'
      }
    })
  end

  specify do
    expect(hidden_items_property).to eql({
      'type' => 'array',
      'description' => 'This is a nested entity with hidden props',
      'items' => {
        '$ref' => '#/definitions/Issue962_EntityWithHiddenProperty'
      }
    })
  end

  specify do
    expect(empty_entity_definition).to eql({
      'type' => 'object',
      'properties' => {}
    })
  end

  specify do
    expect(hidden_entity_definition).to eql({
      'type' => 'object',
      'properties' => {}
    })
  end

  let(:response_schema) { subject['paths']['/issue_962']['get']['responses']['200']['schema'] }

  specify do
    expect(response_schema).to eql({
      '$ref' => '#/definitions/Issue962_EntityWithNestedEmptyEntity'
    })
  end
end
