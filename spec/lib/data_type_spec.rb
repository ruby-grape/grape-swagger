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

    it { expect(subject).to eql 'object' }
  end

  describe 'Multi types in a string' do
    let(:value) { { type: '[String, Integer]' } }

    it { expect(subject).to eql 'string' }
  end

  describe 'Multi types in array' do
    let(:value) { { type: [String, Integer] } }

    it { expect(subject).to eql 'string' }
  end

  describe 'Rack::Multipart::UploadedFile' do
    let(:value) { { type: Rack::Multipart::UploadedFile } }

    it { expect(subject).to eql 'file' }
  end

  describe 'Virtus::Attribute::Boolean' do
    let(:value) { { type: Virtus::Attribute::Boolean } }

    it { expect(subject).to eql 'boolean' }
  end

  describe 'BigDecimal' do
    let(:value) { { type: BigDecimal } }

    it { expect(subject).to eql 'double' }
  end

  describe 'DateTime' do
    let(:value) { { type: DateTime } }

    it { expect(subject).to eql 'dateTime' }
  end

  describe 'Numeric' do
    let(:value) { { type: Numeric } }

    it { expect(subject).to eql 'long' }
  end

  describe 'Symbol' do
    let(:value) { { type: Symbol } }

    it { expect(subject).to eql 'string' }
  end

  describe '[String]' do
    let(:value) { { type: '[String]' } }

    it { expect(subject).to eq('string') }
  end

  describe '[Integer]' do
    let(:value) { { type: '[Integer]' } }

    it { expect(subject).to eq('integer') }
  end
end
