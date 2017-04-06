# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::DocMethods::Version do
  let(:route) { OpenStruct.new(version: version) }
  subject { described_class.get(route) }

  describe 'grape 0.16.2 version' do
    let(:version) { '[:v1, :v2]' }
    it { is_expected.to be_a Array }
    it { is_expected.to eql %i[v1 v2] }
  end

  describe 'newer grape versions' do
    describe 'as String' do
      let(:version) { 'v1' }
      it { is_expected.to be_a String }
      it { is_expected.to eql 'v1' }
    end

    describe 'as Array' do
      let(:version) { %i[v1 v2] }
      it { is_expected.to be_a Array }
      it { is_expected.to eql %i[v1 v2] }
    end
  end
end
