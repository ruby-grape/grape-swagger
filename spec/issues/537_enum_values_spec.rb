require 'spec_helper'

describe '#537 enum values spec' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_539 do
        class Spec < Grape::Entity
          expose :test_property, documentation: { values: [:foo, :bar] }
        end

        desc 'create account',
             success: Spec
        get do
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  let(:property) { subject['definitions']['Spec']['properties']['test_property'] }

  specify do
    expect(property).to include 'enum'
    expect(property['enum']).to eql %w(foo bar)
  end
end
