require 'spec_helper'

describe Grape::Endpoint do
  subject { described_class.new(Grape::Util::InheritableSetting.new, path: '/', method: :get) }

  describe '#param_type_is_array?' do
    it 'returns true if the value passed represents an array' do
      expect(subject.send(:param_type_is_array?, 'Array')).to be_truthy
      expect(subject.send(:param_type_is_array?, '[String]')).to be_truthy
      expect(subject.send(:param_type_is_array?, 'Array[Integer]')).to be_truthy
    end

    it 'returns false if the value passed does not represent an array' do
      expect(subject.send(:param_type_is_array?, 'String')).to be_falsey
      expect(subject.send(:param_type_is_array?, '[String, Integer]')).to be_falsey
    end
  end
end
