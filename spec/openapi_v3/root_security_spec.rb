# frozen_string_literal: true

require 'spec_helper'

describe 'Root security without security_definitions' do
  %w[3.0 3.1].each do |version|
    context "with openapi_version #{version}" do
      let(:app) do
        v = version
        Class.new(Grape::API) do
          get('/x') { {} }
          add_swagger_documentation(openapi_version: v, security: [{ api_key: [] }])
        end
      end

      subject { JSON.parse(get('/swagger_doc').body) }

      it 'emits the root security requirement like Swagger 2.0 does' do
        expect(subject['security']).to eq([{ 'api_key' => [] }])
      end
    end
  end
end
