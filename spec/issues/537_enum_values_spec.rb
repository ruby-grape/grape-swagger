# frozen_string_literal: true

require 'spec_helper'

describe '#537 enum values spec' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_537 do
        class Spec < Grape::Entity
          expose :enum_property, documentation: { values: %i[foo bar] }
          expose :enum_property_default, documentation: { values: %w[a b c], default: 'c' }
          expose :own_format, documentation: { format: 'log' }
        end

        desc 'create account',
             success: Spec
        get do
          { message: 'hi' }
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  let(:property) { subject['definitions']['Spec']['properties']['enum_property'] }
  specify do
    expect(property).to include 'enum'
    expect(property['enum']).to eql %w[foo bar]
  end

  let(:property_default) { subject['definitions']['Spec']['properties']['enum_property_default'] }
  specify do
    expect(property_default).to include 'enum'
    expect(property_default['enum']).to eql %w[a b c]
    expect(property_default).to include 'default'
    expect(property_default['default']).to eql 'c'
  end

  let(:own_format) { subject['definitions']['Spec']['properties']['own_format'] }
  specify do
    expect(own_format).to include 'format'
    expect(own_format['format']).to eql 'log'
  end
end
