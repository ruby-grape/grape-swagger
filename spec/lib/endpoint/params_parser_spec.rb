# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::Endpoint::ParamsParser do
  let(:settings) { {} }
  let(:params) { [] }
  let(:endpoint) { nil }

  let(:parser) { described_class.new(nil, params, settings, endpoint) }

  describe '#parse_request_params' do
    subject(:parse_request_params) { parser.parse_request_params }

    context 'when param is of array type' do
      let(:params) { [['param_1', { type: 'Array[String]' }]] }

      it 'adds is_array option' do
        expect(parse_request_params['param_1']).to eq(type: 'Array[String]', is_array: true)
      end

      context 'and array_use_braces setting set to true' do
        let(:settings) { { array_use_braces: true } }

        it 'adds braces to the param key' do
          expect(parse_request_params.keys.first).to eq 'param_1[]'
        end
      end
    end

    context 'when param is of simple type' do
      let(:params) { [['param_1', { type: 'String' }]] }

      it 'does not change options' do
        expect(parse_request_params['param_1']).to eq(type: 'String')
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

      context 'and array_use_braces setting set to true' do
        let(:settings) { { array_use_braces: true } }

        it 'adds braces to the param key' do
          expect(parse_request_params.keys.last).to eq 'param_1[param_2]'
        end
      end
    end

    context 'when param is nested in a param of hash type' do
      let(:params) { [param_1, param_2] }
      let(:param_1) { ['param_1', { type: 'Hash' }] }
      let(:param_2) { ['param_1[param_2]', { type: 'String' }] }

      context 'and array_use_braces setting set to true' do
        let(:settings) { { array_use_braces: true } }

        context 'and param is of simple type' do
          it 'does not add braces to the param key' do
            expect(parse_request_params.keys.last).to eq 'param_1[param_2]'
          end
        end

        context 'and param is of array type' do
          let(:param_2) { ['param_1[param_2]', { type: 'Array[String]' }] }

          it 'adds braces to the param key' do
            expect(parse_request_params.keys.last).to eq 'param_1[param_2][]'
          end

          context 'and `param_type` option is set to body' do
            let(:param_2) do
              ['param_1[param_2]', { type: 'Array[String]', documentation: { param_type: 'body' } }]
            end

            it 'does not add braces to the param key' do
              expect(parse_request_params.keys.last).to eq 'param_1[param_2]'
            end
          end

          context 'and `in` option is set to body' do
            let(:param_2) do
              ['param_1[param_2]', { type: 'Array[String]', documentation: { in: 'body' } }]
            end

            it 'does not add braces to the param key' do
              expect(parse_request_params.keys.last).to eq 'param_1[param_2]'
            end
          end

          context 'and hash `param_type` option is set to body' do
            let(:param_1) { ['param_1', { type: 'Hash', documentation: { param_type: 'body' } }] }

            it 'does not add braces to the param key' do
              expect(parse_request_params.keys.last).to eq 'param_1[param_2]'
            end
          end
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
