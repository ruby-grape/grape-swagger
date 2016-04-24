require 'spec_helper'

describe GrapeSwagger::DocMethods::OperationId do
  subject { described_class }

  specify { expect(subject).to eql GrapeSwagger::DocMethods::OperationId }
  specify { expect(subject).to respond_to :build }

  describe 'build' do
    let(:route) { Grape::Route.new({ method: method })}

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
    describe 'GET with path foo' do
      let(:method) { 'GET' }
      specify { expect(subject.build(route, 'foo')).to eql 'getFoo' }
    end
    describe 'GET with path /foo' do
      let(:method) { 'GET' }
      specify { expect(subject.build(route, '/foo')).to eql 'getFoo' }
    end
    describe 'GET with path bar/foo' do
      let(:method) { 'GET' }
      specify { expect(subject.build(route, 'bar/foo')).to eql 'getBarFoo' }
    end
    describe 'GET with path bar/foo{id}' do
      let(:method) { 'GET' }
      specify { expect(subject.build(route, 'bar/foo{id}')).to eql 'getBarFooId' }
    end
    describe 'GET with path /bar_foo{id}' do
      let(:method) { 'GET' }
      specify { expect(subject.build(route, '/bar_foo{id}')).to eql 'getBarFooId' }
    end
    describe 'GET with path /bar-foo{id}' do
      let(:method) { 'GET' }
      specify { expect(subject.build(route, '/bar-foo{id}')).to eql 'getBarFooId' }
    end
    describe 'GET with path /simple_test/bar-foo{id}' do
      let(:method) { 'GET' }
      specify { expect(subject.build(route, '/simple_test/bar-foo{id}')).to eql 'getSimpleTestBarFooId' }
    end
  end

end
