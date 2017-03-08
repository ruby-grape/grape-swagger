# frozen_string_literal: true
require 'spec_helper'

describe GrapeSwagger::DocMethods::PathString do
  subject { described_class }

  specify { expect(subject).to eql GrapeSwagger::DocMethods::PathString }
  specify { expect(subject).to respond_to :build }

  describe 'path_string_object' do
    specify 'The original route path is not mutated' do
      route = Struct.new(:version, :path).new
      route.path = '/foo/:dynamic/bar'
      subject.build(route, add_version: true)
      expect(route.path).to eq '/foo/:dynamic/bar'
    end

    describe 'version' do
      describe 'defaults: given, true' do
        let(:options) { { add_version: true } }
        let(:route) { Struct.new(:version, :path).new('v1') }

        specify 'The returned path includes version' do
          route.path = '/{version}/thing(.json)'
          expect(subject.build(route, options)).to eql ['Thing', '/v1/thing']
          route.path = '/{version}/thing/foo(.json)'
          expect(subject.build(route, options)).to eql ['Foo', '/v1/thing/foo']
          route.path = '/{version}/thing(.:format)'
          expect(subject.build(route, options)).to eql ['Thing', '/v1/thing']
          route.path = '/{version}/thing/foo(.:format)'
          expect(subject.build(route, options)).to eql ['Foo', '/v1/thing/foo']
          route.path = '/{version}/thing/:id'
          expect(subject.build(route, options)).to eql ['Thing', '/v1/thing/{id}']
          route.path = '/{version}/thing/foo/:id'
          expect(subject.build(route, options)).to eql ['Foo', '/v1/thing/foo/{id}']
        end
      end

      describe 'defaults: not given, both false' do
        let(:options) { { add_version: false } }
        let(:route) { Struct.new(:version, :path).new }

        specify 'The returned path does not include version' do
          route.path = '/{version}/thing(.json)'
          expect(subject.build(route, options)).to eql ['Thing', '/thing']
          route.path = '/{version}/thing/foo(.json)'
          expect(subject.build(route, options)).to eql ['Foo', '/thing/foo']
          route.path = '/{version}/thing(.:format)'
          expect(subject.build(route, options)).to eql ['Thing', '/thing']
          route.path = '/{version}/thing/foo(.:format)'
          expect(subject.build(route, options)).to eql ['Foo', '/thing/foo']
          route.path = '/{version}/thing/:id'
          expect(subject.build(route, options)).to eql ['Thing', '/thing/{id}']
          route.path = '/{version}/thing/foo/:id'
          expect(subject.build(route, options)).to eql ['Foo', '/thing/foo/{id}']
        end
      end

      describe 'defaults: add_version false' do
        let(:options) { { add_version: false } }
        let(:route) { Struct.new(:version, :path).new('v1') }

        specify 'The returned path does not include version' do
          route.path = '/{version}/thing(.json)'
          expect(subject.build(route, options)).to eql ['Thing', '/thing']
          route.path = '/{version}/thing/foo(.json)'
          expect(subject.build(route, options)).to eql ['Foo', '/thing/foo']
          route.path = '/{version}/thing(.:format)'
          expect(subject.build(route, options)).to eql ['Thing', '/thing']
          route.path = '/{version}/thing/foo(.:format)'
          expect(subject.build(route, options)).to eql ['Foo', '/thing/foo']
          route.path = '/{version}/thing/:id'
          expect(subject.build(route, options)).to eql ['Thing', '/thing/{id}']
          route.path = '/{version}/thing/foo/:id'
          expect(subject.build(route, options)).to eql ['Foo', '/thing/foo/{id}']
        end
      end

      describe 'defaults: root_version nil' do
        let(:options) { { add_version: true } }
        let(:route) { Struct.new(:version, :path).new }

        specify 'The returned path does not include version' do
          route.path = '/{version}/thing(.json)'
          expect(subject.build(route, options)).to eql ['Thing', '/thing']
          route.path = '/{version}/thing/foo(.json)'
          expect(subject.build(route, options)).to eql ['Foo', '/thing/foo']
          route.path = '/{version}/thing(.:format)'
          expect(subject.build(route, options)).to eql ['Thing', '/thing']
          route.path = '/{version}/thing/foo(.:format)'
          expect(subject.build(route, options)).to eql ['Foo', '/thing/foo']
          route.path = '/{version}/thing/:id'
          expect(subject.build(route, options)).to eql ['Thing', '/thing/{id}']
          route.path = '/{version}/thing/foo/:id'
          expect(subject.build(route, options)).to eql ['Foo', '/thing/foo/{id}']
        end
      end
    end
  end
end
