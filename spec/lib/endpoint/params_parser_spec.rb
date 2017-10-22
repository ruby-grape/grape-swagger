# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::Endpoint::ParamsParser do
  let(:settings) { {} }
  let(:params) { [] }

  let(:parser) { described_class.new(params, settings) }

  describe '#parse_request_params' do
    context 'when param is of array type' do
      let(:params) { [['param_1', { type: 'Array[String]' }]] }

      it 'adds is_array option' do
        expect(parser.parse_request_params).to eq('param_1' => { type: 'Array[String]', is_array: true })
      end

      context 'and array_use_braces setting set to true' do
        let(:settings) { { array_use_braces: true } }

        it 'adds braces to the param key' do
          expect(parser.parse_request_params.keys.first).to eq 'param_1[]'
        end
      end
    end

    context 'when param is of simple type' do
      let(:params) { [['param_1', { type: 'String' }]] }

      it 'does not change options' do
        expect(parser.parse_request_params).to eq('param_1' => { type: 'String' })
      end

      context 'and array_use_braces setting set to true' do
        let(:settings) { { array_use_braces: true } }

        it 'does not add braces to the param key' do
          expect(parser.parse_request_params.keys.first).to eq 'param_1'
        end
      end
    end

    context 'when param is nested in a param of array type' do
      let(:params) { [['param_1', { type: 'Array' }], ['param_1[param_2]', { type: 'String' }]] }

      it 'skips root parameter' do
        expect(parser.parse_request_params).not_to have_key 'param_1'
      end

      it 'adds is_array option to the nested param' do
        expect(parser.parse_request_params).to eq('param_1[param_2]' => { type: 'String', is_array: true })
      end

      context 'and array_use_braces setting set to true' do
        let(:settings) { { array_use_braces: true } }

        it 'adds braces to the param key' do
          expect(parser.parse_request_params.keys.first).to eq 'param_1[][param_2]'
        end
      end
    end

    context 'when param is nested in a param of hash type' do
      let(:params) { [['param_1', { type: 'Hash' }], ['param_1[param_2]', { type: 'String' }]] }

      it 'skips root parameter' do
        expect(parser.parse_request_params).not_to have_key 'param_1'
      end

      it 'does not change options to the nested param' do
        expect(parser.parse_request_params).to eq('param_1[param_2]' => { type: 'String' })
      end

      context 'and array_use_braces setting set to true' do
        let(:settings) { { array_use_braces: true } }

        it 'does not add braces to the param key' do
          expect(parser.parse_request_params.keys.first).to eq 'param_1[param_2]'
        end
      end
    end
  end

  describe '#param_type_is_array?' do
    it 'returns true if the value passed represents an array' do
      expect(parser.send(:param_type_is_array?, 'Array')).to be_truthy
      expect(parser.send(:param_type_is_array?, '[String]')).to be_truthy
      expect(parser.send(:param_type_is_array?, 'Array[Integer]')).to be_truthy
    end

    it 'returns false if the value passed does not represent an array' do
      expect(parser.send(:param_type_is_array?, 'String')).to be_falsey
      expect(parser.send(:param_type_is_array?, '[String, Integer]')).to be_falsey
    end
  end
end
