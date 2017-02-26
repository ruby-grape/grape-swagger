require 'spec_helper'

describe '#XXX nested entity given as string' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :range_parameter do

        desc 'Get a array with range'
        get '/range/:range_start-:range_end' do
          present []
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    result = JSON.parse(last_response.body)['paths']
    result
  end

  specify { expect(subject.keys).to include '/range_parameter/range/{range_start}-{range_end}' }
end
