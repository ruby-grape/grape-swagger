# frozen_string_literal: true
require 'spec_helper'

describe GrapeSwagger::DocMethods::ProducesConsumes do
  describe ':json (default)' do
    subject { described_class.call }

    specify do
      expect(subject).to eql(['application/json'])
    end
  end

  describe 'accept symbols of' do
    describe 'single' do
      subject { described_class.call(:xml) }

      specify do
        expect(subject).to eql(['application/xml'])
      end
    end

    describe 'multiple' do
      subject { described_class.call(:xml, :serializable_hash, :json, :binary, :txt) }

      specify do
        expect(subject).to eql(
          [
            'application/xml',
            'application/json',
            'application/octet-stream',
            'text/plain'
          ]
        )
      end
    end
  end

  describe 'accept mime_types of' do
    describe 'single' do
      subject { described_class.call('application/xml') }

      specify do
        expect(subject).to eql(['application/xml'])
      end
    end

    describe 'multiple' do
      subject do
        described_class.call(
          'application/xml',
          'application/json',
          'application/octet-stream',
          'text/plain'
        )
      end

      specify do
        expect(subject).to eql(
          [
            'application/xml',
            'application/json',
            'application/octet-stream',
            'text/plain'
          ]
        )
      end
    end
  end

  describe 'mix it up' do
    subject do
      described_class.call(
        :xml,
        :serializable_hash,
        'application/json',
        'application/octet-stream',
        :txt
      )
    end

    specify do
      expect(subject).to eql(
        [
          'application/xml',
          'application/json',
          'application/octet-stream',
          'text/plain'
        ]
      )
    end

    subject do
      described_class.call(
        [
          :xml,
          :serializable_hash,
          'application/json',
          'application/octet-stream',
          :txt
        ]
      )
    end

    specify do
      expect(subject).to eql(
        [
          'application/xml',
          'application/json',
          'application/octet-stream',
          'text/plain'
        ]
      )
    end
  end
end
