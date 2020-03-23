# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GrapeSwagger::Rake::OapiTasks do
  module Api
    class Item < Grape::API
      version 'v1', using: :path

      namespace :item do
        get '/'
      end

      namespace :otherItem do
        get '/'
      end
    end

    class Base < Grape::API
      prefix :api
      mount Api::Item
      add_swagger_documentation add_version: true
    end
  end

  subject { described_class.new(Api::Base) }

  describe '.new' do
    it 'accepts class name as a constant' do
      expect(described_class.new(::Api::Base).send(:api_class)).to eq(Api::Base)
    end

    it 'accepts class name as a string' do
      expect(described_class.new('::Api::Base').send(:api_class)).to eq(Api::Base)
    end
  end

  describe '#make_request' do
    describe 'complete documentation' do
      before do
        subject.send(:make_request)
      end

      describe 'not storing' do
        it 'has no error' do
          expect(subject.send(:error?)).to be false
        end

        it 'does not allow to save' do
          expect(subject.send(:save_to_file?)).to be false
        end

        it 'requests doc url' do
          expect(subject.send(:url_for)).to eql '/api/swagger_doc'
        end
      end

      describe 'store it' do
        before { ENV['store'] = 'true' }
        after { ENV.delete('store') }

        it 'allows to save' do
          expect(subject.send(:save_to_file?)).to be true
        end
      end
    end

    describe 'documentation for resource' do
      before do
        ENV['resource'] = resource
        subject.send(:make_request)
      end

      let(:response) { JSON.parse(subject.send(:make_request)) }

      after { ENV.delete('resource') }

      describe 'valid name' do
        let(:resource) { 'otherItem' }

        it 'has no error' do
          expect(subject.send(:error?)).to be false
        end

        it 'requests doc url' do
          expect(subject.send(:url_for)).to eql "/api/swagger_doc/#{resource}"
        end

        it 'has only one resource path' do
          expect(response['paths'].length).to eql 1
          expect(response['paths'].keys.first).to end_with resource
        end
      end

      describe 'wrong name' do
        let(:resource) { 'foo' }

        it 'has error' do
          expect(subject.send(:error?)).to be true
        end
      end

      describe 'empty name' do
        let(:resource) { nil }

        it 'has no error' do
          expect(subject.send(:error?)).to be false
        end

        it 'returns complete doc' do
          expect(response['paths'].length).to eql 2
        end
      end
    end

    describe 'call it' do
      before do
        subject.send(:make_request)
      end
      specify do
        expect(subject).to respond_to :oapi
        expect(subject.oapi).to be_a String
        expect(subject.oapi).not_to be_empty
      end
    end
  end

  describe '#file' do
    describe 'no store given' do
      it 'returns swagger_doc.json' do
        expect(subject.send(:file)).to end_with 'swagger_doc.json'
      end
    end

    describe 'store given' do
      after { ENV.delete('store') }

      describe 'boolean true' do
        before { ENV['store'] = 'true' }

        it 'returns swagger_doc.json' do
          expect(subject.send(:file)).to end_with 'swagger_doc.json'
        end
      end

      describe 'name given' do
        let(:name) { 'oapi_doc.json' }
        before { ENV['store'] = name }

        it 'returns swagger_doc.json' do
          expect(subject.send(:file)).to end_with name
        end
      end
    end
  end
end
