# frozen_string_literal: true

require 'spec_helper'

RSpec::Matchers.define_negated_matcher :exclude, :include

describe '#884 dont document non-schema examples' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_884 do
        params do
          requires :id, type: Integer, documentation: { example: 123 }
          optional :name, type: String, documentation: { example: 'Buddy Guy' }
        end

        post 'document_example' do
          present params
        end

        desc 'do not document this' do
          consumes ['application/x-www-form-urlencoded']
        end
        params do
          requires :id, type: Integer, documentation: { example: 123 }
          optional :name, type: String, documentation: { example: 'Buddy Guy' }
        end

        post 'dont_document_example' do
          present params
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  let(:parameters_document_example) { subject['definitions']['postIssue884DocumentExample']['properties'] }
  let(:parameters_dont_document_example) { subject['paths']['/issue_884/dont_document_example']['post']['parameters'] }

  specify do
    expect(parameters_document_example.values).to all(include('example'))
    expect(parameters_dont_document_example).to all(exclude('example'))
  end
end
