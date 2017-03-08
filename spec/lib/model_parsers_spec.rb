# frozen_string_literal: true
require 'spec_helper'

describe GrapeSwagger::ModelParsers do
  let(:model_parsers) { described_class.new }
  let(:parser) { Class.new }
  let(:parser2) { Class.new }
  let(:parser3) { Class.new }

  describe '#register' do
    describe 'successfully register new parser' do
      before do
        model_parsers.register(parser, Class)
      end

      specify do
        expect(model_parsers.to_a).to eq([[parser, 'Class']])
      end
    end

    describe 'should be empty if no registered parsers' do
      specify do
        expect(model_parsers.to_a).to be_empty
      end
    end
  end

  describe '#insert_before' do
    describe 'SomeModelParser2 should be first parser' do
      before do
        model_parsers.register(parser, Class)
        model_parsers.register(parser3, Class)
        model_parsers.insert_before(parser, parser2, Class)
      end

      specify do
        expect(model_parsers.count).to eq(3)
        expect(model_parsers.to_a.first).to eq([parser2, Class])
      end
    end

    describe 'SomeModelParser2 should be inserted anyway if SomeModelParser not registered' do
      before do
        model_parsers.register(parser3, Class)
        model_parsers.insert_before(parser, parser2, Class)
      end

      specify do
        expect(model_parsers.count).to eq(2)
        expect(model_parsers.to_a).to include([parser2, Class])
      end
    end

    describe 'SomeModelParser2 should be inserted anyway if model parsers is empty' do
      before do
        model_parsers.insert_before(parser, parser2, Class)
      end

      specify do
        expect(model_parsers.count).to eq(1)
        expect(model_parsers.to_a).to include([parser2, Class])
      end
    end
  end

  describe '#insert_after' do
    describe 'SomeModelParser2 should be second parser' do
      before do
        model_parsers.register(parser, Class)
        model_parsers.register(parser3, Class)
        model_parsers.insert_after(parser, parser2, Class)
      end

      specify do
        expect(model_parsers.count).to eq(3)
        expect(model_parsers.to_a[1]).to eq([parser2, Class])
      end
    end

    describe 'SomeModelParser2 should be inserted anyway if SomeModelParser not registered' do
      before do
        model_parsers.register(parser3, Class)
        model_parsers.insert_after(parser, parser2, Class)
      end

      specify do
        expect(model_parsers.count).to eq(2)
        expect(model_parsers.to_a).to include([parser2, Class])
      end
    end

    describe 'SomeModelParser2 should be inserted anyway if model parsers is empty' do
      before do
        model_parsers.insert_after(parser, parser2, Class)
      end

      specify do
        expect(model_parsers.count).to eq(1)
        expect(model_parsers.to_a).to include([parser2, Class])
      end
    end
  end
end
