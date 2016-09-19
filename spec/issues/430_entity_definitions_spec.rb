require 'spec_helper'
require 'grape-entity'
require 'grape-swagger-entity'

describe 'definition names' do
  before :all do
    module TestDefinition
      module DummyEntities
        module WithVeryLongName
          module AnotherGroupingModule
            class Class1
              class Entity < Grape::Entity
                expose :one_thing
              end
            end

            class Class2
              class Entity < Grape::Entity
                expose :another_thing

                def self.entity_name
                  'FooKlass'
                end
              end
            end
          end
        end
      end

      class NameApi < Grape::API
        add_swagger_documentation models: [
          DummyEntities::WithVeryLongName::AnotherGroupingModule::Class1::Entity,
          DummyEntities::WithVeryLongName::AnotherGroupingModule::Class2::Entity
        ]
      end
    end
  end

  let(:app) { TestDefinition::NameApi }

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)['definitions']
  end

  specify { expect(subject).to include 'AnotherGroupingModuleClass1' }
  specify { expect(subject).to include 'FooKlass' }
end
