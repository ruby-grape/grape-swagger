require 'spec_helper'

describe GrapeSwagger::DocMethods::PathString do
  subject { described_class }

  specify { expect(subject).to eql GrapeSwagger::DocMethods::PathString }
  specify { expect(subject).to respond_to :build }

  describe 'operation_id_object' do
    describe 'version' do
      describe 'defaults: given, true' do
        let(:options) { { add_version: true } }
        let(:version) { 'v1' }

        specify 'The returned path includes version' do
          expect(subject.build('/{version}/thing(.json)', version, options)).to eql ['Thing', '/v1/thing']
          expect(subject.build('/{version}/thing/foo(.json)', version, options)).to eql ['Foo', '/v1/thing/foo']
          expect(subject.build('/{version}/thing(.:format)', version, options)).to eql ['Thing', '/v1/thing']
          expect(subject.build('/{version}/thing/foo(.:format)', version, options)).to eql ['Foo', '/v1/thing/foo']
          expect(subject.build('/{version}/thing/:id', version, options)).to eql ['Thing', '/v1/thing/{id}']
          expect(subject.build('/{version}/thing/foo/:id', version, options)).to eql ['Foo', '/v1/thing/foo/{id}']
        end
      end

      describe 'defaults: not given, both false' do
        let(:options) { { add_version: false } }
        let(:version) { nil }

        specify 'The returned path does not include version' do
          expect(subject.build('/thing(.json)', version, options)).to eql ['Thing', '/thing']
          expect(subject.build('/thing/foo(.json)', version, options)).to eql ['Foo', '/thing/foo']
          expect(subject.build('/thing(.:format)', version, options)).to eql ['Thing', '/thing']
          expect(subject.build('/thing/foo(.:format)', version, options)).to eql ['Foo', '/thing/foo']
          expect(subject.build('/thing/:id', version, options)).to eql ['Thing', '/thing/{id}']
          expect(subject.build('/thing/foo/:id', version, options)).to eql ['Foo', '/thing/foo/{id}']
        end
      end

      describe 'defaults: add_version false' do
        let(:options) { { add_version: false } }
        let(:version) { 'v1' }

        specify 'The returned path does not include version' do
          expect(subject.build('/thing(.json)', version, options)).to eql ['Thing', '/thing']
          expect(subject.build('/thing/foo(.json)', version, options)).to eql ['Foo', '/thing/foo']
          expect(subject.build('/thing(.:format)', version, options)).to eql ['Thing', '/thing']
          expect(subject.build('/thing/foo(.:format)', version, options)).to eql ['Foo', '/thing/foo']
          expect(subject.build('/thing/:id', version, options)).to eql ['Thing', '/thing/{id}']
          expect(subject.build('/thing/foo/:id', version, options)).to eql ['Foo', '/thing/foo/{id}']
        end
      end

      describe 'defaults: root_version nil' do
        let(:options) { { add_version: true } }
        let(:version) { nil }

        specify 'The returned path does not include version' do
          expect(subject.build('/thing(.json)', version, options)).to eql ['Thing', '/thing']
          expect(subject.build('/thing/foo(.json)', version, options)).to eql ['Foo', '/thing/foo']
          expect(subject.build('/thing(.:format)', version, options)).to eql ['Thing', '/thing']
          expect(subject.build('/thing/foo(.:format)', version, options)).to eql ['Foo', '/thing/foo']
          expect(subject.build('/thing/:id', version, options)).to eql ['Thing', '/thing/{id}']
          expect(subject.build('/thing/foo/:id', version, options)).to eql ['Foo', '/thing/foo/{id}']
        end
      end
    end
  end
end
