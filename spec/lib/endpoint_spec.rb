# frozen_string_literal: true

require 'spec_helper'

describe Grape::Endpoint do
  subject do
    described_class.new(Grape::Util::InheritableSetting.new, path: '/', method: :get)
  end

  describe '.content_types_for' do
    describe 'defined on target_class' do
      let(:own_json) { 'text/own-json' }
      let(:own_xml) { 'text/own-xml' }
      let(:content_types) do
        {
          own_json: own_json,
          own_xml: own_xml
        }
      end
      let(:target_class) { OpenStruct.new(content_types: content_types) }

      let(:object) { subject.content_types_for(target_class) }
      specify do
        expect(object).to eql [own_json, own_xml]
      end
    end

    describe 'not defined' do
      describe 'format given' do
        let(:format) { :json }
        let(:target_class) { OpenStruct.new(format: format) }
        let(:object) { subject.content_types_for(target_class) }
        specify do
          expect(object).to eql ['application/json']
        end

        describe 'format not given' do
          let(:target_class) { OpenStruct.new }
          let(:object) { subject.content_types_for(target_class) }

          specify do
            expect(object).to eql %w[application/xml application/json text/plain]
          end
        end
      end
    end
  end
end
