require 'spec_helper'

describe GrapeSwagger::DocMethods::Extensions do
  describe "#extended? and extension" do
    subject { described_class }
    describe "return false (default)" do
      let(:part) { {foo: 'bar', bar: 'foo'} }

      specify do
        expect(subject.extended?(part)).to be false
        expect(subject.extension(part)).to be_empty
      end
    end

    describe "return true" do
      specify do
        part = { foo: 'bar', bar: 'foo', x: 'something' }
        expect(subject.extended?(part)).to be true
        expect(subject.extension(part)).to eql({ x: 'something' })
        expect(subject.extended?(part, :x)).to be true
        expect(subject.extension(part, :x)).to eql({ x: 'something' })
      end

      specify do
        part = { foo: 'bar', bar: 'foo', x_path: 'something' }
        expect(subject.extended?(part, :x_path)).to be true
        expect(subject.extension(part, :x_path)).to eql({ x_path: 'something' })
      end

      specify do
        part = { foo: 'bar', bar: 'foo', x_def: 'something' }
        expect(subject.extended?(part, :x_def)).to be true
        expect(subject.extension(part, :x_def)).to eql({ x_def: 'something' })
      end

      specify do
        part = { foo: 'bar', bar: 'foo', x_path: 'something', x_def: 'something' }
        expect(subject.extended?(part, :x_path)).to be true
        expect(subject.extension(part, :x_path)).to eql({ x_path: 'something' })
        expect(subject.extended?(part, :x_def)).to be true
        expect(subject.extension(part, :x_def)).to eql({ x_def: 'something' })
      end
    end
  end

  describe "concatenate" do
    describe "not nested" do
      describe "simple" do
        let(:extensions) { {x: {key_1: 'foo'}} }
        let(:result) { {'x-key_1' => 'foo'} }
        subject { described_class.concatenate(extensions) }

        specify do
          expect(subject).to eql result
        end
      end

      describe "multiple" do
        let(:extensions) { {x: {key_1: 'foo', key_2: 'bar'}} }
        let(:result) { {'x-key_1' => 'foo', 'x-key_2' => 'bar'} }
        subject { described_class.concatenate(extensions) }

        specify do
          expect(subject).to eql result
        end
      end
    end

    describe "nested" do
      describe "simple" do
        let(:extensions) { {x: {key_1: { key_2: 'foo'}}} }
        let(:result) { {'x-key_1' => { key_2: 'foo'}} }
        subject { described_class.concatenate(extensions) }

        specify do
          expect(subject).to eql result
        end
      end

      describe "simple multiple" do
        let(:extensions) { {x: {key_1: { key_2: 'foo', key_3: 'bar'}}} }
        let(:result) { {'x-key_1' => { key_2: 'foo', key_3: 'bar'}} }
        subject { described_class.concatenate(extensions) }

        specify do
          expect(subject).to eql result
        end
      end

      describe "simple deeper" do
        let(:extensions) { {x: {key_1: { key_2: {key_3: 'foo'}}}} }
        let(:result) { {'x-key_1' => { key_2: {key_3: 'foo'}}} }
        subject { described_class.concatenate(extensions) }

        specify do
          expect(subject).to eql result
        end
      end

      describe "multiple" do
        let(:extensions) { {x: {key_1: { key_3: 'foo'}, key_2: { key_3: 'bar' }}} }
        let(:result) { {'x-key_1' => { key_3: 'foo'}, 'x-key_2' => { key_3: 'bar' }} }
        subject { described_class.concatenate(extensions) }

        specify do
          expect(subject).to eql result
        end
      end
    end

    describe "reale example" do
      let(:extensions) { {x: {
        'amazon-apigateway-auth' => {type: 'none'},
        'amazon-apigateway-integration' => {type: 'aws', uri: 'foo_bar_uri', httpMethod: 'get'}
      }} }
      let(:result) { {
        'x-amazon-apigateway-auth' => {type: 'none'},
        'x-amazon-apigateway-integration' => {type: 'aws', uri: 'foo_bar_uri', httpMethod: 'get'}
      } }
      subject { described_class.concatenate(extensions) }

      specify do
        expect(subject).to eql result
      end
    end
  end
end
