# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::DocMethods::DataType do
  subject { described_class.call(value) }

  describe 'standards' do
    ['Boolean', Date, Integer, String, Float].each do |type|
      specify do
        data_type = described_class.call(type: type)
        expect(data_type).to eql type.to_s.downcase
      end
    end
  end

  describe 'Hash' do
    let(:value) { { type: Hash } }

    it { is_expected.to eq 'object' }
  end

  describe 'Multi types in a string' do
    let(:value) { { type: '[String, Integer]' } }

    it { is_expected.to eq 'string' }
  end

  describe 'Multi types in a string stating with A' do
    let(:value) { { type: '[Apple, Orange]' } }

    it { is_expected.to eq 'Apple' }
  end

  describe 'Multi types in array' do
    let(:value) { { type: [String, Integer] } }

    it { is_expected.to eq 'string' }
  end

  describe 'Types in array with entity_name' do
    before do
      stub_const 'MyEntity', Class.new
      allow(MyEntity).to receive(:entity_name).and_return 'MyInteger'
    end

    let(:value) { { type: '[MyEntity]' } }

    it { is_expected.to eq 'MyInteger' }
  end

  describe 'Rack::Multipart::UploadedFile' do
    let(:value) { { type: Rack::Multipart::UploadedFile } }

    it { is_expected.to eq 'file' }
  end

  describe 'Virtus::Attribute::Boolean' do
    let(:value) { { type: Virtus::Attribute::Boolean } }

    it { is_expected.to eq 'boolean' }
  end

  describe 'BigDecimal' do
    let(:value) { { type: BigDecimal } }

    it { is_expected.to eq 'double' }
  end

  describe 'DateTime' do
    let(:value) { { type: DateTime } }

    it { is_expected.to eq 'dateTime' }
  end

  describe 'Numeric' do
    let(:value) { { type: Numeric } }

    it { is_expected.to eq 'long' }
  end

  describe 'Symbol' do
    let(:value) { { type: Symbol } }

    it { is_expected.to eq 'string' }
  end

  describe '[String]' do
    let(:value) { { type: '[String]' } }

    it { is_expected.to eq('string') }
  end

  describe '[Integer]' do
    let(:value) { { type: '[Integer]' } }

    it { is_expected.to eq('integer') }
  end

  describe 'Custom Type with :name method defined' do
    class CustomNumericObject
      def self.data_type
        'integer'
      end
    end

    let(:value) { { type: 'CustomNumericObject' } }

    it { is_expected.to eq('Integer') }
  end
end
