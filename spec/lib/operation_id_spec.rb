# frozen_string_literal: false

require 'spec_helper'

describe GrapeSwagger::DocMethods::OperationId do
  subject { described_class }

  specify { expect(subject).to eql GrapeSwagger::DocMethods::OperationId }
  specify { expect(subject).to respond_to :build }

  describe 'build' do
    let(:route) { RouteHelper.build(method: method, pattern: '/path', options: { requirements: {} }) }

    describe 'GET' do
      let(:method) { 'GET' }
      specify { expect(subject.build(route)).to eql 'get' }
    end
    describe 'get' do
      let(:method) { 'get' }
      specify { expect(subject.build(route)).to eql 'get' }
    end
    describe ':get' do
      let(:method) { :get }
      specify { expect(subject.build(route)).to eql 'get' }
    end

    describe 'path given' do
      let(:method) { 'GET' }
      it 'GET with path foo' do
        expect(subject.build(route, 'foo')).to eql 'getFoo'
      end
      it 'GET with path /foo' do
        expect(subject.build(route, '/foo')).to eql 'getFoo'
      end
      it 'GET with path bar/foo' do
        expect(subject.build(route, 'bar/foo')).to eql 'getBarFoo'
      end
      it 'GET with path bar/foo{id}' do
        expect(subject.build(route, 'bar/foo{id}')).to eql 'getBarFooId'
      end
      it 'GET with path /bar_foo{id}' do
        expect(subject.build(route, '/bar_foo{id}')).to eql 'getBarFooId'
      end
      it 'GET with path /bar-foo{id}' do
        expect(subject.build(route, '/bar-foo{id}')).to eql 'getBarFooId'
      end
      it 'GET with path /simple_test/bar-foo{id}' do
        expect(subject.build(route, '/simple_test/bar-foo{id}')).to eql 'getSimpleTestBarFooId'
      end
      it 'GET path with optional format' do
        expect(subject.build(route, 'foo(.{format})')).to eql 'getFoo(.Format)'
      end
    end
  end
end
