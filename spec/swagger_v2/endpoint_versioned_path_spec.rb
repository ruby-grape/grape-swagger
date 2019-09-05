# frozen_string_literal: true

require 'spec_helper'

describe 'Grape::Endpoint#path_and_definitions' do
  context 'when mounting an API once' do
    let(:item) do
      Class.new(Grape::API) do
        version 'v1', using: :path

        resource :item do
          get '/'
        end
      end
    end

    let(:api) do
      item_api = item

      Class.new(Grape::API) do
        mount item_api
        add_swagger_documentation add_version: true
      end
    end

    let(:options) { { add_version: true } }
    let(:target_routes) { api.combined_namespace_routes }

    subject { api.endpoints[0].path_and_definition_objects(target_routes, options) }

    it 'is returning a versioned path' do
      expect(subject[0].keys[0]).to eq '/v1/item'
    end

    it 'tags the endpoint with the resource name' do
      expect(subject.first['/v1/item'][:get][:tags]).to eq ['item']
    end

    context 'when custom tags are specified' do
      let(:item) do
        Class.new(Grape::API) do
          version 'v1', using: :path

          resource :item do
            desc 'Item description', tags: ['special-item']
            get '/'
          end
        end
      end

      it 'tags the endpoint with the custom tags' do
        expect(subject.first['/v1/item'][:get][:tags]).to eq ['special-item']
      end
    end

    context 'when parameter with a custom type is specified' do
      let(:item) do
        Class.new(Grape::API) do
          Color = Struct.new(:value) do
            def self.parse(value)
              new(value: value)
            end
          end

          class ColorEntity < Grape::Entity
            expose :value
          end

          version 'v1', using: :path

          resource :item do
            params do
              requires :root, type: Hash do
                optional :color, type: Color, documentation: { type: ColorEntity }
              end
            end
            post '/'
          end
        end
      end

      it 'creates a reference to the model instead of using the non-existent type' do
        color = subject.dig(1, 'postV1Item', :properties, :root, :properties, :color)
        expect(color).not_to eq(type: 'ColorEntity')
        expect(color).to eq('$ref' => '#/definitions/ColorEntity')
      end
    end
  end

  context 'when mounting an API more than once', if: GrapeVersion.satisfy?('>= 1.2.0') do
    let(:item) do
      Class.new(Grape::API) do
        resource :item do
          desc 'Item description', tags: [configuration[:tag] || 'item']
          get '/'
        end
      end
    end

    let(:api) do
      item_api = item
      Class.new(Grape::API) do
        version 'v1', using: :path do
          mount item_api
        end

        version 'v2', using: :path do
          mount item_api, with: { tag: 'special-item' }
        end

        add_swagger_documentation add_version: true
      end
    end

    let(:options) { { add_version: true } }
    let(:target_routes) { api.combined_namespace_routes }

    subject { api.endpoints[0].path_and_definition_objects(target_routes, options) }

    it 'retrieves both apis respecting their configured tags' do
      expect(subject.first['/v1/item'][:get][:tags]).to eq ['item']
      expect(subject.first['/v2/item'][:get][:tags]).to eq ['special-item']
    end

    it 'retrieves both apis with descriptions' do
      expect(subject.first['/v1/item'][:get][:description]).to eq 'Item description'
      expect(subject.first['/v2/item'][:get][:description]).to eq 'Item description'
    end
  end
end
