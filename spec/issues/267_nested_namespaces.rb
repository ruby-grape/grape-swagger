# frozen_string_literal: true

require 'spec_helper'

describe 'nested namespaces' do
  let(:app) do
    Class.new(Grape::API) do
      route_param :root do
        resources :apps do
          route_param :app_id do
            resource :build do
              desc 'Builds an application'
              post do
                { name: 'Test' }
              end
            end
          end
        end
      end

      add_swagger_documentation version: 'v1'
    end
  end

  describe 'combined_namespace_routes' do
    it 'parses root namespace properly' do
      expect(app.combined_namespace_routes.keys).to include('apps')
    end
  end

  describe '#extract_parent_route' do
    it 'extracts parent for non-namespaced path properly' do
      expect(app.send(:extract_parent_route, '/apps/:app_id/build')).to eq('apps')
    end

    it 'extracts parent for namespaced path properly' do
      expect(app.send(:extract_parent_route, '/:root/apps/:app_id/build')).to eq('apps')
    end
  end

  describe 'retrieves swagger-documentation on /swagger_doc' do
    let(:route_name) { '{root}/apps/{app_id}/build' }

    subject do
      get '/swagger_doc.json'
      JSON.parse(last_response.body)
    end

    context 'paths' do
      specify do
        expect(subject['paths'].keys).to include "/#{route_name}"
      end
    end
  end
end
