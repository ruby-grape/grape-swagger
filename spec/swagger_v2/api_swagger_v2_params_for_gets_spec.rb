require 'spec_helper'

describe 'parameters should never be of type body or formData for GET methods' do
  before :all do
    module TheApi
      class ParamGetApi < Grape::API
        resource :resource do
          desc 'Simple listing of resources'
          params do
            optional :string_filter, type: Array(String)
          end
          get '/' do
            []
          end
        end

        add_swagger_documentation
      end
    end
  end

  let(:app) { TheApi::ParamGetApi }

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  specify 'no parameter is defined as body or formData' do
    pending 'This is failing with the current implementation, what could be done?'
    subject['paths'].each do |_path, methods|
      next unless methods.key?('get')
      methods['get']['parameters'].each do |parameter|
        expect(parameter['in']).not_to match(/formData|body/)
      end
    end
  end
end
