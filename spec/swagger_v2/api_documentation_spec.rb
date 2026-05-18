# frozen_string_literal: true

require 'spec_helper'

describe 'API with additional options' do
  let(:api) do
    Class.new(Grape::API) do
      add_swagger_documentation \
        api_documentation: { desc: 'Swagger compatible API description' },
        specific_api_documentation: { desc: 'Swagger compatible API description for specific API' }
    end
  end

  subject do
    api.routes.map do |route|
      route.settings[:description]
    end
  end

  it 'documents api' do
    expect(subject.pluck(:description)).to match_array [
      'Swagger compatible API description',
      'Swagger compatible API description for specific API'
    ]
  end

  context 'when api_documentation is string-keyed' do
    let(:api) do
      Class.new(Grape::API) do
        add_swagger_documentation api_documentation: { 'desc' => 'String-keyed description' }
      end
    end

    it 'accepts string keys' do
      expect(subject.first[:description]).to eq('String-keyed description')
    end
  end

  context 'when api_documentation uses :description instead of :desc' do
    let(:api) do
      Class.new(Grape::API) do
        add_swagger_documentation api_documentation: { description: 'Via description key' }
      end
    end

    it 'falls back to :description' do
      expect(subject.first[:description]).to eq('Via description key')
    end
  end

  context 'when both :desc and :description are supplied' do
    let(:api) do
      Class.new(Grape::API) do
        add_swagger_documentation api_documentation: { desc: 'Desc wins', description: 'Description loses' }
      end
    end

    it ':desc takes precedence' do
      expect(subject.pluck(:description)).to include('Desc wins')
    end
  end

  context 'when :desc is explicitly nil' do
    let(:api) do
      Class.new(Grape::API) do
        add_swagger_documentation api_documentation: { desc: nil, description: 'fallback' }
      end
    end

    it 'respects the explicit nil and does not fall through to :description' do
      expect(subject.pluck(:description)).not_to include('fallback')
    end
  end

  context 'when specific_api_documentation uses :description' do
    let(:api) do
      Class.new(Grape::API) do
        add_swagger_documentation specific_api_documentation: { description: 'Specific via description' }
      end
    end

    it 'accepts :description on the specific endpoint too' do
      expect(subject.pluck(:description)).to include('Specific via description')
    end
  end
end
