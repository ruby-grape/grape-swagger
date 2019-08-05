# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::DocMethods::FormatData do
  let(:subject) { GrapeSwagger::DocMethods::FormatData }

  [true, false].each do |array_use_braces|
    context 'when param is nested in a param of array type' do
      let(:braces) { array_use_braces ? '[]' : '' }
      let(:params) do
        [
          { in: 'formData', name: "param1#{braces}", type: 'array', items: { type: 'string' } },
          { in: 'formData', name: 'param1[param2]', type: 'string' }
        ]
      end

      it 'skips root parameter' do
        expect(subject.to_format(params).first).not_to have_key "param1#{braces}"
      end

      it 'Move array type to param2' do
        expect(subject.to_format(params).first).to include(name: "param1#{braces}[param2]", type: 'array')
      end
    end
  end

  context 'when param is nested in a param of hash type' do
    let(:params) { [{ in: 'formData', type: 'object', name: 'param1' }, { in: 'formData', name: 'param1[param2]', type: 'string' }] }

    it 'skips root parameter' do
      expect(subject.to_format(params).first).not_to have_key 'param1'
    end

    it 'Move array type to param2' do
      expect(subject.to_format(params).first).to include(name: 'param1[param2]', type: 'string')
    end
  end
end
