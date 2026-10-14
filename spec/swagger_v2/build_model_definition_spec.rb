# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::DocMethods::BuildModelDefinition do
  describe '.build' do
    it 'keeps only required names that exist as properties' do
      properties = { id: { type: 'integer' }, 'name' => { type: 'string' } }

      definition = described_class.build(nil, properties, %i[id name secret])

      expect(definition[:required]).to eq(%i[id name])
    end

    it 'omits required when none of the names is a property' do
      definition = described_class.build(nil, { id: { type: 'integer' } }, [:hidden])

      expect(definition).not_to have_key(:required)
    end
  end
end
