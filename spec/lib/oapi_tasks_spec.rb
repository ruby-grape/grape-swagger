require 'spec_helper'

RSpec.describe GrapeSwagger::Rake::OapiTasks do
  let(:api) do
    item = Class.new(Grape::API) do
      version 'v1', using: :path

      resource :item do
        get '/'
      end

      resource :otherItem do
        get '/'
      end
    end

    Class.new(Grape::API) do
      prefix :api
      mount item
      add_swagger_documentation add_version: true
    end
  end

  subject { described_class.new(api) }

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
