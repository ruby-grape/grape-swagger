# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::DocMethods::OptionalObject do
  subject { described_class }

  specify { expect(subject).to eql GrapeSwagger::DocMethods::OptionalObject }
  specify { expect(subject).to respond_to :build }

  describe 'build' do
    let(:key) { :host }
    let!(:request) { Rack::Request.new(Rack::MockRequest.env_for('http://example.com:8080/')) }

    describe 'no option given for host, take from request' do
      let(:options) { { foo: 'foo' } }
      specify do
        expect(subject.build(key, options, request)).to eql request.host_with_port
      end
    end

    let(:value) { 'grape-swagger.example.com' }

    describe 'option is a string' do
      let(:options) { { host: value } }
      specify do
        expect(subject.build(key, options, request)).to eql value
      end
    end

    describe 'option is a lambda' do
      let(:options) { { host: -> { value } } }
      specify do
        expect(subject.build(key, options, request)).to eql value
      end
    end

    describe 'option is a proc' do
      let(:options) do
        { host: proc { |request| request.host =~ /^example/ ? '/api-example' : '/api' } }
      end
      specify do
        expect(subject.build(key, options, request)).to eql '/api-example'
      end
    end
  end
end
