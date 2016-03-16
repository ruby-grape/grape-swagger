require 'spec_helper'

describe GrapeSwagger::DocMethods::PathString do
  subject { described_class }

  specify { expect(subject).to eql GrapeSwagger::DocMethods::PathString }
  specify { expect(subject).to respond_to :build }

  describe 'operation_id_object' do
    describe 'version' do
      describe 'defaults: not given, false' do
        let(:options) {{ add_version: false }}

        specify do
          expect(subject.build('/thing(.json)', options)).to eql ['Thing', '/thing']
          expect(subject.build('/thing/foo(.json)', options)).to eql ['Foo', '/thing/foo']
          expect(subject.build('/thing(.:format)', options)).to eql ['Thing', '/thing']
          expect(subject.build('/thing/foo(.:format)', options)).to eql ['Foo', '/thing/foo']
          expect(subject.build('/thing/:id', options)).to eql ['Thing', '/thing/{id}']
          expect(subject.build('/thing/foo/:id', options)).to eql ['Foo', '/thing/foo/{id}']
        end
      end

      describe 'defaults: given, true' do
        let(:options) {{ version: 'v1', add_version: true }}

        specify do
          expect(subject.build('/{version}/thing(.json)', options)).to eql ['Thing', '/v1/thing']
          expect(subject.build('/{version}/thing/foo(.json)', options)).to eql ['Foo', '/v1/thing/foo']
          expect(subject.build('/{version}/thing(.:format)', options)).to eql ['Thing', '/v1/thing']
          expect(subject.build('/{version}/thing/foo(.:format)', options)).to eql ['Foo', '/v1/thing/foo']
          expect(subject.build('/{version}/thing/:id', options)).to eql ['Thing', '/v1/thing/{id}']
          expect(subject.build('/{version}/thing/foo/:id', options)).to eql ['Foo', '/v1/thing/foo/{id}']
        end

      end
    end
  end
end
