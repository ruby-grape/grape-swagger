# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::DocMethods::Extensions do
  context 'it should not break method introspection' do
    describe '.method' do
      describe 'method introspection' do
        specify do
          expect(described_class.method(described_class.methods.first)).to be_a(Method)
        end
      end
    end
  end

  describe '#find_definition' do
    subject { described_class }

    let(:method) { :get }
    let(:status) { 200 }

    before { allow(subject).to receive(:method).and_return(method) }

    describe 'no response for status' do
      let(:path) { { get: { responses: {} } } }

      specify do
        definition = subject.find_definition(status, path)
        expect(definition).to be_nil
      end
    end

    describe 'response found' do
      let(:model) { 'Item' }

      describe 'ref given' do
        let(:path) do
          { get: { responses: { 200 => { schema: { '$ref' => "#/definitions/#{model}" } } } } }
        end
        specify do
          definition = subject.find_definition(status, path)
          expect(definition).to eql model
        end
      end

      describe 'items given' do
        let(:path) do
          { get: { responses: { 200 => { schema: { 'items' => { '$ref' => "#/definitions/#{model}" } } } } } }
        end
        specify do
          definition = subject.find_definition(status, path)
          expect(definition).to eql model
        end
      end
    end
  end

  describe '#extended? and extension' do
    subject { described_class }
    describe 'return false (default)' do
      let(:part) { { foo: 'bar', bar: 'foo' } }

      specify do
        expect(subject.extended?(part)).to be false
        expect(subject.extension(part)).to be_empty
      end
    end

    describe 'return true' do
      specify do
        part = { foo: 'bar', bar: 'foo', x: 'something' }
        expect(subject.extended?(part)).to be true
        expect(subject.extension(part)).to eql(x: 'something')
        expect(subject.extended?(part, :x)).to be true
        expect(subject.extension(part, :x)).to eql(x: 'something')
      end

      specify do
        part = { foo: 'bar', bar: 'foo', x_path: 'something' }
        expect(subject.extended?(part, :x_path)).to be true
        expect(subject.extension(part, :x_path)).to eql(x_path: 'something')
      end

      specify do
        part = { foo: 'bar', bar: 'foo', x_def: 'something' }
        expect(subject.extended?(part, :x_def)).to be true
        expect(subject.extension(part, :x_def)).to eql(x_def: 'something')
      end

      specify do
        part = { foo: 'bar', bar: 'foo', x_path: 'something', x_def: 'something' }
        expect(subject.extended?(part, :x_path)).to be true
        expect(subject.extension(part, :x_path)).to eql(x_path: 'something')
        expect(subject.extended?(part, :x_def)).to be true
        expect(subject.extension(part, :x_def)).to eql(x_def: 'something')
      end
    end
  end

  describe 'concatenate' do
    describe 'not nested' do
      describe 'simple' do
        let(:extensions) { { x: { key_1: 'foo' } } }
        let(:result) { { 'x-key_1' => 'foo' } }
        subject { described_class.concatenate(extensions) }

        specify do
          expect(subject).to eql result
        end
      end

      describe 'multiple' do
        let(:extensions) { { x: { key_1: 'foo', key_2: 'bar' } } }
        let(:result) { { 'x-key_1' => 'foo', 'x-key_2' => 'bar' } }
        subject { described_class.concatenate(extensions) }

        specify do
          expect(subject).to eql result
        end
      end
    end

    describe 'nested' do
      describe 'simple' do
        let(:extensions) { { x: { key_1: { key_2: 'foo' } } } }
        let(:result) { { 'x-key_1' => { key_2: 'foo' } } }
        subject { described_class.concatenate(extensions) }

        specify do
          expect(subject).to eql result
        end
      end

      describe 'simple multiple' do
        let(:extensions) { { x: { key_1: { key_2: 'foo', key_3: 'bar' } } } }
        let(:result) { { 'x-key_1' => { key_2: 'foo', key_3: 'bar' } } }
        subject { described_class.concatenate(extensions) }

        specify do
          expect(subject).to eql result
        end
      end

      describe 'simple deeper' do
        let(:extensions) { { x: { key_1: { key_2: { key_3: 'foo' } } } } }
        let(:result) { { 'x-key_1' => { key_2: { key_3: 'foo' } } } }
        subject { described_class.concatenate(extensions) }

        specify do
          expect(subject).to eql result
        end
      end

      describe 'multiple' do
        let(:extensions) { { x: { key_1: { key_3: 'foo' }, key_2: { key_3: 'bar' } } } }
        let(:result) { { 'x-key_1' => { key_3: 'foo' }, 'x-key_2' => { key_3: 'bar' } } }
        subject { described_class.concatenate(extensions) }

        specify do
          expect(subject).to eql result
        end
      end
    end

    describe 'real example' do
      let(:extensions) do
        { x: {
          'amazon-apigateway-auth' => { type: 'none' },
          'amazon-apigateway-integration' => { type: 'aws', uri: 'foo_bar_uri', httpMethod: 'get' }
        } }
      end
      let(:result) do
        {
          'x-amazon-apigateway-auth' => { type: 'none' },
          'x-amazon-apigateway-integration' => { type: 'aws', uri: 'foo_bar_uri', httpMethod: 'get' }
        }
      end
      subject { described_class.concatenate(extensions) }

      specify do
        expect(subject).to eql result
      end
    end
  end
end
