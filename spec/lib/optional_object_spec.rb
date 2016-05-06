require 'spec_helper'

describe GrapeSwagger::DocMethods::OptionalObject do
  subject { described_class }

  specify { expect(subject).to eql GrapeSwagger::DocMethods::OptionalObject }
  specify { expect(subject).to respond_to :build }

  describe 'build' do
    let(:key) { :bar }
    let(:request) { 'somes/request/string' }

    describe 'no option given for key' do
      let(:options) { { foo: 'foo' } }
      specify do
        expect(subject.build(key, options)).to be_nil
        expect(subject.build(key, options, request)).to eql request
      end
    end

    let(:value) { 'some optional value' }

    describe 'option is a string' do
      let(:options) { { bar: value } }
      specify do
        expect(subject.build(key, options)).to eql value
        expect(subject.build(key, options, request)).to eql value
      end
    end

    describe 'option is a proc' do
      let(:options) { { bar: -> { value } } }
      specify do
        expect(subject.build(key, options)).to eql value
        expect(subject.build(key, options, request)).to eql value
      end
    end
  end
end
