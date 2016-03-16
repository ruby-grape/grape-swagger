require 'spec_helper'

describe GrapeSwagger::DocMethods::OperationId do
  subject { described_class }

  specify { expect(subject).to eql GrapeSwagger::DocMethods::OperationId }
  specify { expect(subject).to respond_to :build }

  describe 'build' do
    specify do
      expect(subject.build('GET')).to eql 'get'
      expect(subject.build('get')).to eql 'get'
      expect(subject.build(:get)).to eql 'get'
      expect(subject.build('GET', 'foo')).to eql 'getFoo'
      expect(subject.build('GET', '/foo')).to eql 'getFoo'
      expect(subject.build('GET', 'bar/foo')).to eql 'getBarFoo'
      expect(subject.build('GET', 'bar/foo{id}')).to eql 'getBarFooId'
      expect(subject.build('GET', '/bar_foo{id}')).to eql 'getBarFooId'
      expect(subject.build('GET', '/bar-foo{id}')).to eql 'getBarFooId'
      expect(subject.build('GET', '/simple_test/bar-foo{id}')).to eql 'getSimpleTestBarFooId'
    end
  end

end
