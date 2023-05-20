# frozen_string_literal: true

require 'spec_helper'

describe 'API with additional options' do
  let(:api) do
    Class.new(Grape::API) do
      add_swagger_documentation \
        api_documentation: { desc: 'Swagger compatible API description' },
        specific_api_documentation: { desc: 'Swagger compatible API description for specific API' }
    end
  end

  subject do
    api.routes.map do |route|
      route.settings[:description]
    end
  end

  it 'documents api' do
    expect(subject.pluck(:description)).to match_array [
      'Swagger compatible API description',
      'Swagger compatible API description for specific API'
    ]
  end
end
