require 'spec_helper'

describe 'helpers' do
  before :all do
    class HelperTestAPI < Grape::API
    end
  end

  subject do
    HelperTestAPI.add_swagger_documentation
  end

  context 'parsing parameters' do
    it 'parses params as query strings for a GET' do
      params = {
        name: { type: 'String', desc: 'A name', required: true, default: 'default' },
        level: 'max'
      }
      path = '/coolness'
      method = 'GET'
      expect(subject.parse_params(params, path, method)).to eq [
        { paramType: 'query', name: :name, description: 'A name', type: 'string', required: true, allowMultiple: false, defaultValue: 'default' },
        { paramType: 'query', name: :level, description: '', type: 'string', required: false, allowMultiple: false }
      ]
    end

    it 'parses params as query strings for a GET with an example' do
      params = {
        name: { type: 'String', desc: 'A name', required: true, default: 'default api value', documentation: { example: 'default swagger value' } },
        level: 'max'
      }
      path = '/coolness'
      method = 'GET'
      expect(subject.parse_params(params, path, method)).to eq [
        { paramType: 'query', name: :name, description: 'A name', type: 'string', required: true, allowMultiple: false, defaultValue: 'default swagger value' },
        { paramType: 'query', name: :level, description: '', type: 'string', required: false, allowMultiple: false }
      ]
    end

    it 'parses params as form for a POST' do
      params = {
        name: { type: 'String', desc: 'A name', required: true },
        level: 'max'
      }
      path = '/coolness'
      method = 'POST'
      expect(subject.parse_params(params, path, method)).to eq [
        { paramType: 'form', name: :name, description: 'A name', type: 'string', required: true, allowMultiple: false },
        { paramType: 'form', name: :level, description: '', type: 'string', required: false, allowMultiple: false }
      ]
    end

    it 'parses file param' do
      params = {
        rack: {
          type: 'Rack::Multipart::UploadedFile',
          desc: 'rack file',
          datafile: 'content',
          required: true
        }
      }
      path = '/coolness'
      method = 'POST'
      expect(subject.parse_params(params, path, method)).to eq [
        {
          paramType: 'body',
          name: :rack,
          description: 'rack file',
          type: 'File',
          required: true,
          allowMultiple: false
        }
      ]
    end

    it 'parses symbol param as string' do
      params = {
        animal: { type: 'Symbol', desc: 'An animal you like', required: true, values: [:cat, :dog] }
      }
      path = '/coolness'
      method = 'POST'
      expect(subject.parse_params(params, path, method)).to eq [
        {
          paramType: 'form',
          name: :animal,
          description: 'An animal you like',
          type: 'string',
          required: true,
          allowMultiple: false,
          enum: [:cat, :dog]
        }
      ]
    end

    context 'custom type' do
      before :all do
        class CustomType
        end
      end
      it 'parses a custom parameters' do
        params = {
          option: { type: CustomType, desc: 'Custom option' }
        }
        path = '/coolness'
        method = 'GET'
        expect(subject.parse_params(params, path, method)).to eq [
          { paramType: 'query', name: :option, description: 'Custom option', type: 'CustomType', required: false, allowMultiple: false }
        ]
      end
    end
  end

  context 'parsing the path' do
    it 'parses the path' do
      path = ':abc/def(.:format)'
      expect(subject.parse_path(path, nil)).to eq '{abc}/def.{format}'
    end

    it 'parses a path that has vars with underscores in the name' do
      path = 'abc/:def_g(.:format)'
      expect(subject.parse_path(path, nil)).to eq 'abc/{def_g}.{format}'
    end

    it 'parses a path that has vars with numbers in the name' do
      path = 'abc/:sha1(.:format)'
      expect(subject.parse_path(path, nil)).to eq 'abc/{sha1}.{format}'
    end

    it 'parses a path that has multiple variables' do
      path1 = 'abc/:def/:geh(.:format)'
      path2 = 'abc/:def:geh(.:format)'
      expect(subject.parse_path(path1, nil)).to eq 'abc/{def}/{geh}.{format}'
      expect(subject.parse_path(path2, nil)).to eq 'abc/{def}{geh}.{format}'
    end

    it 'parses the path with a specified version' do
      path = ':abc/{version}/def(.:format)'
      expect(subject.parse_path(path, 'v1')).to eq '{abc}/v1/def.{format}'
    end
  end

  context 'parsing header parameters' do
    it 'parses params for the header' do
      params = {
        'XAuthToken' => { description: 'A required header.', required: true, default: 'default' }
      }
      expect(subject.parse_header_params(params)).to eq [
        { paramType: 'header', name: 'XAuthToken', description: 'A required header.', type: 'string', required: true, defaultValue: 'default' }
      ]
    end
  end
end
