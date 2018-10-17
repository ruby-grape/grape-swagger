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
    expect(subject).to eq(
      [
        { description: 'Swagger compatible API description' },
        {
          description: 'Swagger compatible API description for specific API',
          params: {
            'locale' => {
              desc: 'Locale of API documentation',
              required: false,
              type: 'Symbol'
            },
            'name' => {
              desc: 'Resource name of mounted API',
              required: true,
              type: 'String'
            }
          }
        }
      ]
    )
  end
end
