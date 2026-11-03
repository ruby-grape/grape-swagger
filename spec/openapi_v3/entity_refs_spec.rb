# frozen_string_literal: true

require 'spec_helper'

describe 'Entity references in OAS 3.x output' do
  before :all do
    module EntityRefsOAS3
      class Address < Grape::Entity
        expose :street, documentation: { type: String, desc: 'Street' }
      end

      class Pet < Grape::Entity
        expose :kind, documentation: { type: String, is_discriminator: true, required: true }
        expose :name, documentation: { type: String }
      end

      class Cat < Pet
        expose :lives, documentation: { type: Integer }
      end

      class User < Grape::Entity
        expose :name, documentation: { type: String, x: { nullable: true } }
        expose :home, documentation: { type: Address }
        expose :work, documentation: { type: Address, desc: 'Work address' }
        expose :mail, documentation: { type: Address, x: { nullable: true } }
        expose :previous, documentation: { type: Address, is_array: true }
        expose :former, documentation: { type: Address, is_array: true, x: { nullable: true } }
      end

      def self.api(version)
        Class.new(Grape::API) do
          format :json

          desc 'User', success: User
          get('/user') { {} }

          desc 'Cat', success: Cat
          get('/cat') { {} }

          add_swagger_documentation(openapi_version: version)
        end
      end
    end
  end

  def schemas_for(version)
    session = Rack::Test::Session.new(Rack::MockSession.new(EntityRefsOAS3.api(version)))
    session.get '/swagger_doc'
    JSON.parse(session.last_response.body)['components']['schemas']
  end

  let(:address_ref) { { '$ref' => '#/components/schemas/EntityRefsOAS3_Address' } }

  {
    '3.0' => { null: { 'type' => 'object', 'nullable' => true, 'enum' => [nil] }, name_type: 'string' },
    '3.1' => { null: { 'type' => 'null' }, name_type: %w[string null] }
  }.each do |version, expected|
    describe "OpenAPI #{version}" do
      subject(:schemas) { schemas_for(version) }

      let(:props) { schemas['EntityRefsOAS3_User']['properties'] }

      it 'keeps a plain nested entity as a bare $ref' do
        expect(props['home']).to eq(address_ref)
      end

      it 'wraps a nested entity with a description in allOf' do
        expect(props['work']).to eq('description' => 'Work address', 'allOf' => [address_ref])
      end

      it 'turns a nullable entity into a union with null' do
        expect(props['mail']).to eq('anyOf' => [address_ref, expected[:null]])
      end

      it 'keeps entity arrays with a bare item $ref' do
        expect(props['previous']).to eq('type' => 'array', 'items' => address_ref)
      end

      it 'marks a nullable entity array nullable on the array, not its items' do
        expect(props['former']).to include('items' => address_ref)
        expect(props['former']).to include(version == '3.0' ? { 'nullable' => true } : { 'type' => %w[array null] })
      end

      it 'keeps nullable on scalar entity properties' do
        name = props['name']

        if version == '3.0'
          expect(name).to include('type' => 'string', 'nullable' => true)
        else
          expect(name['type']).to eq(expected[:name_type])
        end
      end

      it 'exports the discriminator as an object' do
        expect(schemas['EntityRefsOAS3_Pet']['discriminator']).to eq('propertyName' => 'kind')
      end

      it 'keeps the allOf parent link of an inherited entity' do
        expect(schemas['EntityRefsOAS3_Cat']['allOf'].first)
          .to eq('$ref' => '#/components/schemas/EntityRefsOAS3_Pet')
      end
    end
  end
end
