require 'spec_helper'

describe 'API Description' do
  context 'with no additional options' do
    subject do
      Class.new(Grape::API) do
        add_swagger_documentation
      end
    end

    it 'describes the API with defaults' do
      routes = subject.endpoints.first.routes
      expect(routes.count).to eq 2
      expect(routes.first.route_description).to eq 'Swagger compatible API description'
      expect(routes.first.route_params).to eq('locale' => { desc: 'Locale of API documentation', type: 'Symbol', required: false })
      expect(routes.last.route_description).to eq 'Swagger compatible API description for specific API'
      expect(routes.last.route_params).to eq('name' => { desc: 'Resource name of mounted API', type: 'String', required: true },
                                             'locale' => { desc: 'Locale of API documentation', type: 'Symbol', required: false })
    end
  end

  context 'with additional options' do
    subject do
      Class.new(Grape::API) do
        add_swagger_documentation \
          api_documentation: { desc: 'First', params: { x: 1 }, xx: 11 },
          specific_api_documentation: { desc: 'Second', params: { y: 42 }, yy: 4242 }
      end
    end

    it 'describes the API with defaults' do
      routes = subject.endpoints.first.routes
      expect(routes.count).to eq 2
      expect(routes.first.route_description).to eq 'First'
      expect(routes.first.route_params).to eq(x: 1, 'locale' => { desc: 'Locale of API documentation', type: 'Symbol', required: false })
      expect(routes.first.route_xx).to eq(11)
      expect(routes.last.route_description).to eq 'Second'
      expect(routes.last.route_params).to eq('name' => { desc: 'Resource name of mounted API', type: 'String', required: true }, y: 42,
                                             'locale' => { desc: 'Locale of API documentation', type: 'Symbol', required: false })
      expect(routes.last.route_yy).to eq(4242)
    end
  end
end
