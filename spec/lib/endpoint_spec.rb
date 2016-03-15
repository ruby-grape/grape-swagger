require 'spec_helper'

describe Grape::Endpoint do
  subject { described_class.new(Grape::Util::InheritableSetting.new, {path: '/', method: :get}) }

  describe 'operation_id_object' do
    specify do
      expect(subject.operation_id_object('GET')).to eql 'get'
      expect(subject.operation_id_object('get')).to eql 'get'
      expect(subject.operation_id_object(:get)).to eql 'get'
      expect(subject.operation_id_object('GET', 'foo')).to eql 'getFoo'
      expect(subject.operation_id_object('GET', '/foo')).to eql 'getFoo'
      expect(subject.operation_id_object('GET', 'bar/foo')).to eql 'getBarFoo'
      expect(subject.operation_id_object('GET', 'bar/foo{id}')).to eql 'getBarFooId'
      expect(subject.operation_id_object('GET', '/bar_foo{id}')).to eql 'getBarFooId'
      expect(subject.operation_id_object('GET', '/bar-foo{id}')).to eql 'getBarFooId'
      expect(subject.operation_id_object('GET', '/simple_test/bar-foo{id}')).to eql 'getSimpleTestBarFooId'
    end
  end

end
