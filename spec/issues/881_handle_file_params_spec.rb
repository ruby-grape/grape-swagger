# frozen_string_literal: true

require 'spec_helper'

describe '#881 handle file params' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_881 do
        params do
          requires :upload, type: File
        end

        post do
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

  let(:consumes) { subject['paths']['/issue_881']['post']['consumes'] }
  let(:parameters) { subject['paths']['/issue_881']['post']['parameters'] }

  specify do
    expect(consumes).to eql(
        ["application/x-www-form-urlencoded", "multipart/form-data"]
    )
    expect(parameters).to eql(
        [{"in"=>"formData", "name"=>"upload", "required"=>true, "type"=>"file"}]
    )
  end
end
