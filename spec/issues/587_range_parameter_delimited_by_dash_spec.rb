# frozen_string_literal: true
require 'spec_helper'

describe '#587 process route with parameters delimited by dash' do
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
    JSON.parse(last_response.body)['paths']
  end

  specify { expect(subject.keys).to include '/range_parameter/range/{range_start}-{range_end}' }
  specify { expect(subject['/range_parameter/range/{range_start}-{range_end}']['get']['operationId']).to eql 'getRangeParameterRangeRangeStart-RangeEnd' }
end
