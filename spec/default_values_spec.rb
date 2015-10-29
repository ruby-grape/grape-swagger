require 'spec_helper'
require 'grape_version'

describe 'Parse default values' do
  subject do
    test_class = Class.new(Grape::API)
    test_class.add_swagger_documentation
  end

  it 'parses immediate defaults' do
    params = {
      name: { type: 'String', default: 'default' }
    }

    value = subject.parse_params(params, '/', 'GET').first
    expect(value[:defaultValue]).to eq('default')
  end

  it 'parses delayed defaults' do
    params = {
      name: { type: 'String', default: -> { 'default' } }
    }

    value = subject.parse_params(params, '/', 'GET').first
    expect(value[:defaultValue]).to eq('default')
  end
end
