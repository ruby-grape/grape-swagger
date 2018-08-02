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

  describe 'parse_request_params' do
    before do
      subject.send(:parse_request_params, params)
    end

    context 'when params do not contain an array' do
      let(:params) do
        [
          ['id', { required: true, type: 'String' }],
          ['description', { required: false, type: 'String' }]
        ]
      end

      let(:expected_params) do
        [
          ['id', { required: true, type: 'String' }],
          ['description', { required: false, type: 'String' }]
        ]
      end

      it 'parses params correctly' do
        expect(params).to eq expected_params
      end
    end

    context 'when params contain a simple array' do
      let(:params) do
        [
          ['id', { required: true, type: 'String' }],
          ['description', { required: false, type: 'String' }],
          ['stuffs', { required: true, type: 'Array[String]' }]
        ]
      end

      let(:expected_params) do
        [
          ['id', { required: true, type: 'String' }],
          ['description', { required: false, type: 'String' }],
          ['stuffs', { required: true, type: 'Array[String]', is_array: true }]
        ]
      end

      it 'parses params correctly and adds is_array to the array' do
        expect(params).to eq expected_params
      end
    end

    context 'when params contain a complex array' do
      let(:params) do
        [
          ['id', { required: true, type: 'String' }],
          ['description', { required: false, type: 'String' }],
          ['stuffs', { required: true, type: 'Array' }],
          ['stuffs[id]', { required: true, type: 'String' }]
        ]
      end

      let(:expected_params) do
        [
          ['id', { required: true, type: 'String' }],
          ['description', { required: false, type: 'String' }],
          ['stuffs', { required: true, type: 'Array', is_array: true }],
          ['stuffs[id]', { required: true, type: 'String', is_array: true }]
        ]
      end

      it 'parses params correctly and adds is_array to the array and all elements' do
        expect(params).to eq expected_params
      end

      context 'when array params are not contiguous with parent array' do
        let(:params) do
          [
            ['id', { required: true, type: 'String' }],
            ['description', { required: false, type: 'String' }],
            ['stuffs', { required: true, type: 'Array' }],
            ['stuffs[owners]', { required: true, type: 'Array' }],
            ['stuffs[creators]', { required: true, type: 'Array' }],
            ['stuffs[owners][id]', { required: true, type: 'String' }],
            ['stuffs[creators][id]', { required: true, type: 'String' }],
            ['stuffs_and_things', { required: true, type: 'String' }]
          ]
        end

        let(:expected_params) do
          [
            ['id', { required: true, type: 'String' }],
            ['description', { required: false, type: 'String' }],
            ['stuffs', { required: true, type: 'Array', is_array: true }],
            ['stuffs[owners]', { required: true, type: 'Array', is_array: true }],
            ['stuffs[creators]', { required: true, type: 'Array', is_array: true }],
            ['stuffs[owners][id]', { required: true, type: 'String', is_array: true }],
            ['stuffs[creators][id]', { required: true, type: 'String', is_array: true }],
            ['stuffs_and_things', { required: true, type: 'String' }]
          ]
        end

        it 'parses params correctly and adds is_array to the array and all elements' do
          expect(params).to eq expected_params
        end
      end
    end
  end
end
