require 'spec_helper'

describe GrapeSwagger::DocMethods::ParseParams do
  subject { described_class }
  let(:start_value) { -5 }
  let(:end_value) { 5 }

  describe '#parse_range_values' do
    specify do
      parsed_range = subject.send(:parse_range_values, start_value..end_value)
      expect(parsed_range).to eql(minimum: start_value, maximum: end_value)
    end
  end

  describe '#parse_enum_or_range_values' do
    describe 'value as Range' do
      describe 'first Integer' do
        specify do
          parsed_range = subject.send(:parse_enum_or_range_values, start_value..end_value)
          expect(parsed_range).to eql(minimum: start_value, maximum: end_value)
        end
      end

      describe 'first String' do
        specify do
          parsed_range = subject.send(:parse_enum_or_range_values, 'a'..'z')
          expect(parsed_range).to be_nil
        end
      end
    end

    describe 'value as Proc' do
      describe 'as Range' do
        let(:values) { proc { start_value..end_value } }
        specify do
          parsed_range = subject.send(:parse_enum_or_range_values, values)
          expect(parsed_range).to eql(minimum: start_value, maximum: end_value)
        end
      end

      describe 'as Array' do
        let(:values) { proc { %w(a b c) } }
        specify do
          parsed_range = subject.send(:parse_enum_or_range_values, values)
          expect(parsed_range).to eql(enum: %w(a b c))
        end
      end
    end

    describe 'values as Array -> enums' do
      let(:values) { %w(a b c) }
      specify do
        parsed_range = subject.send(:parse_enum_or_range_values, values)
        expect(parsed_range).to eql(enum: %w(a b c))
      end
    end
  end
end
