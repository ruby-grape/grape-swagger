require 'spec_helper'

describe 'API Models' do
  before :all do
    module Entities
      class Something < Grape::Entity
        expose :text, documentation: { type: 'string', desc: 'Content of something.' }
        expose :links, documentation: { type: 'link', is_array: true }
      end
    end

    module Entities
      class EnumValues < Grape::Entity
        expose :gender, documentation: { type: 'string', desc: 'Content of something.', values: %w(Male Female) }
        expose :number, documentation: { type: 'integer', desc: 'Content of something.', values: proc { [1, 2] } }
      end
    end

    module Entities
      module Some
        class Thing < Grape::Entity
          expose :text, documentation: { type: 'string', desc: 'Content of something.' }
        end
      end
    end

    module Entities
      class ComposedOf < Grape::Entity
        expose :part_text, documentation: { type: 'string', desc: 'Content of composedof.' }
      end

      class ComposedOfElse < Grape::Entity
        def self.entity_name
          'composed'
        end
        expose :part_text, documentation: { type: 'string', desc: 'Content of composedof else.' }
      end

      class SomeThingElse < Grape::Entity
        expose :else_text, documentation: { type: 'string', desc: 'Content of something else.' }
        expose :parts, using: Entities::ComposedOf, documentation: { type: 'ComposedOf',
                                                                     is_array: true,
                                                                     required: true }

        expose :part, using: Entities::ComposedOfElse, documentation: { type: 'composes' }
      end
    end

    module Entities
      class AliasedThing < Grape::Entity
        expose :something, as: :post, using: Entities::Something, documentation: { type: 'Something', desc: 'Reference to something.' }
      end
    end

    module Entities
      class FourthLevel < Grape::Entity
        expose :text, documentation: { type: 'string' }
      end

      class ThirdLevel < Grape::Entity
        expose :parts, using: Entities::FourthLevel, documentation: { type: 'FourthLevel' }
      end

      class SecondLevel < Grape::Entity
        expose :parts, using: Entities::ThirdLevel, documentation: { type: 'ThirdLevel' }
      end

      class FirstLevel < Grape::Entity
        expose :parts, using: Entities::SecondLevel, documentation: { type: 'SecondLevel' }
      end
    end
  end

  module Entities
    class QueryInputElement < Grape::Entity
      expose :key, documentation: {
        type: String, desc: 'Name of parameter', required: true }
      expose :value, documentation: {
        type: String, desc: 'Value of parameter', required: true }
    end

    class QueryInput < Grape::Entity
      expose :elements, using: Entities::QueryInputElement, documentation: {
        type: 'QueryInputElement',
        desc: 'Set of configuration',
        param_type: 'body',
        is_array: true,
        required: true
      }
    end

    class QueryResult < Grape::Entity
      expose :elements_size, documentation: { type: Integer, desc: 'Return input elements size' }
    end
  end

  module Entities
    class ThingWithRoot < Grape::Entity
      root 'things', 'thing'
      expose :text, documentation: { type: 'string', desc: 'Content of something.' }
    end
  end

  def app
    Class.new(Grape::API) do
      format :json
      desc 'This gets something.', entity: Entities::Something

      get '/something' do
        something = OpenStruct.new text: 'something'
        present something, with: Entities::Something
      end

      desc 'This gets thing.', entity: Entities::Some::Thing
      get '/thing' do
        thing = OpenStruct.new text: 'thing'
        present thing, with: Entities::Some::Thing
      end

      desc 'This gets somthing else.', entity: Entities::SomeThingElse
      get '/somethingelse' do
        part = OpenStruct.new part_text: 'part thing'
        thing = OpenStruct.new else_text: 'else thing', parts: [part], part: part

        present thing, with: Entities::SomeThingElse
      end

      desc 'This tests the enum values in params and documentation.', entity: Entities::EnumValues, params: Entities::EnumValues.documentation
      get '/enum_description_in_entity' do
        enum_value = OpenStruct.new gender: 'Male', number: 1

        present enum_value, with: Entities::EnumValues
      end

      desc 'This gets an aliased thing.', entity: Entities::AliasedThing
      get '/aliasedthing' do
        something = OpenStruct.new(something: OpenStruct.new(text: 'something'))
        present something, with: Entities::AliasedThing
      end

      desc 'This gets all nested entities.', entity: Entities::FirstLevel
      get '/nesting' do
        fourth_level = OpenStruct.new text: 'something'
        third_level  = OpenStruct.new parts: [fourth_level]
        second_level = OpenStruct.new parts: [third_level]
        first_level  = OpenStruct.new parts: [second_level]

        present first_level, with: Entities::FirstLevel
      end

      desc 'This tests diffrent entity for input and diffrent for output',
           entity: [Entities::QueryResult, Entities::QueryInput],
           params: Entities::QueryInput.documentation
      get '/multiple_entities' do
        result = OpenStruct.new(elements_size: params[:elements].size)
        present result, with: Entities::QueryResult
      end

      desc 'This gets thing_with_root.', entity: Entities::ThingWithRoot
      get '/thing_with_root' do
        thing = OpenStruct.new text: 'thing'
        present thing, with: Entities::ThingWithRoot
      end

      add_swagger_documentation
    end
  end

  context 'swagger_doc' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'returns a swagger-compatible doc' do
      expect(subject).to include(
        'apiVersion' => '0.1',
        'swaggerVersion' => '1.2',
        'info' => {},
        'produces' => ['application/json']
      )
    end

    it 'documents apis' do
      expect(subject['apis']).to eq [
        { 'path' => '/something.{format}', 'description' => 'Operations about somethings' },
        { 'path' => '/thing.{format}', 'description' => 'Operations about things' },
        { 'path' => '/somethingelse.{format}', 'description' => 'Operations about somethingelses' },
        { 'path' => '/enum_description_in_entity.{format}', 'description' => 'Operations about enum_description_in_entities' },
        { 'path' => '/aliasedthing.{format}', 'description' => 'Operations about aliasedthings' },
        { 'path' => '/nesting.{format}', 'description' => 'Operations about nestings' },
        { 'path' => '/multiple_entities.{format}', 'description' => 'Operations about multiple_entities' },
        { 'path' => '/thing_with_root.{format}', 'description' => 'Operations about thing_with_roots' },
        { 'path' => '/swagger_doc.{format}', 'description' => 'Operations about swagger_docs' }
      ]
    end
  end

  it 'returns type' do
    get '/swagger_doc/something'
    result = JSON.parse(last_response.body)
    expect(result['apis'].first['operations'].first['type']).to eq 'Something'
  end

  it 'includes nested type' do
    get '/swagger_doc/thing'
    result = JSON.parse(last_response.body)
    expect(result['apis'].first['operations'].first['type']).to eq 'Some::Thing'
  end

  it 'includes entities which are only used as composition' do
    get '/swagger_doc/somethingelse'
    result = JSON.parse(last_response.body)
    expect(result['apis'][0]['path']).to start_with '/somethingelse'

    expect(result['models']['SomeThingElse']).to include('id' => 'SomeThingElse',
                                                         'properties' => {
                                                           'else_text' => {
                                                             'type' => 'string',
                                                             'description' => 'Content of something else.'
                                                           },
                                                           'parts' => {
                                                             'type' => 'array',
                                                             'items' => { '$ref' => 'ComposedOf' }
                                                           },
                                                           'part' => { '$ref' => 'composes' }
                                                         },
                                                         'required' => ['parts']

                                                        )

    expect(result['models']['ComposedOf']).to include(
      'id' => 'ComposedOf',
      'properties' => {
        'part_text' => {
          'type' => 'string',
          'description' => 'Content of composedof.'
        }
      }
    )

    expect(result['models']['composed']).to include(
      'id' => 'composed',
      'properties' => {
        'part_text' => {
          'type' => 'string',
          'description' => 'Content of composedof else.'
        }

      }
    )
  end

  it 'includes enum values in params and documentation.' do
    get '/swagger_doc/enum_description_in_entity'
    result = JSON.parse(last_response.body)
    expect(result['models']['EnumValues']).to eq(
      'id' => 'EnumValues',
      'properties' => {
        'gender' => { 'type' => 'string', 'description' => 'Content of something.', 'enum' => %w(Male Female) },
        'number' => { 'type' => 'integer', 'format' => 'int32', 'description' => 'Content of something.', 'enum' => [1, 2] }
      }
    )

    expect(result['apis'][0]['operations'][0]).to include(
      'parameters' =>
         [
           { 'paramType' => 'query', 'name' => 'gender', 'description' => 'Content of something.', 'type' => 'string', 'required' => false, 'allowMultiple' => false, 'enum' => %w(Male Female) },
           { 'paramType' => 'query', 'name' => 'number', 'description' => 'Content of something.', 'type' => 'integer', 'required' => false, 'allowMultiple' => false, 'format' => 'int32', 'enum' => [1, 2] }
         ],
      'type' => 'EnumValues'
    )
  end

  it 'includes referenced models in those with aliased references.' do
    get '/swagger_doc/aliasedthing'
    result = JSON.parse(last_response.body)
    expect(result['models']['AliasedThing']).to eq(
      'id' => 'AliasedThing',
      'properties' => {
        'post' => { '$ref' => 'Something', 'description' => 'Reference to something.' }
      }
    )

    expect(result['models']['Something']).to eq(
      'id' => 'Something',
      'properties' => {
        'text' => { 'type' => 'string', 'description' => 'Content of something.' },
        'links' => { 'type' => 'array', 'items' => { '$ref' => 'link' } }
      }
    )
  end

  it 'includes all entities with four levels of nesting' do
    get '/swagger_doc/nesting'
    result = JSON.parse(last_response.body)

    expect(result['models']).to include('FirstLevel', 'SecondLevel', 'ThirdLevel', 'FourthLevel')
  end

  it 'includes all entities while using multiple entities' do
    get '/swagger_doc/multiple_entities'
    result = JSON.parse(last_response.body)

    expect(result['models']).to include('QueryInput', 'QueryInputElement', 'QueryResult')
  end

  it 'includes an id equal to the model name' do
    get '/swagger_doc/thing_with_root'
    result = JSON.parse(last_response.body)
    expect(result['models']['thing']['id']).to eq('thing')
  end
end
