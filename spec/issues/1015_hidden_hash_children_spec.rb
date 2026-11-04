# frozen_string_literal: true

require 'spec_helper'

describe 'hidden parameter with nested children' do
  def parameter_names(path, verb = 'get')
    get '/swagger_doc'
    parameters = JSON.parse(last_response.body).dig('paths', path, verb, 'parameters')
    expect(parameters).not_to be_nil
    parameters.map { |p| p['name'] }
  end

  context 'with query parameters' do
    let(:app) do
      Class.new(Grape::API) do
        format :json

        params do
          optional :query, type: String
          optional :filters, type: Hash, documentation: { hidden: true } do
            optional :status, type: String
            optional :nested, type: Hash do
              optional :kind, type: String
            end
          end
          optional :filters_extra, type: String
          optional :partial, type: Hash do
            optional :shown, type: String
            optional :secret, type: String, documentation: { hidden: true }
          end
          optional :other, type: Hash do
            optional :visible, type: String
          end
          optional :tags, type: Array, documentation: { hidden: true } do
            optional :name, type: String
          end
          optional :proc_hidden, type: Hash, documentation: { hidden: -> { true } } do
            optional :child, type: String
          end
        end
        get('/search') { 'ok' }

        add_swagger_documentation
      end
    end

    it 'hides the nested children together with the parent only' do
      expect(parameter_names('/search')).to eq(%w[query filters_extra partial[shown] other[visible]])
    end
  end

  context 'with a hidden proc that receives the token owner' do
    let(:app) do
      Class.new(Grape::API) do
        format :json

        helpers do
          def current_user
            :admin
          end
        end

        params do
          optional :query, type: String
          optional :filters, type: Hash, documentation: { hidden: ->(user) { user == :admin } } do
            optional :status, type: String
          end
        end
        get('/search') { 'ok' }

        add_swagger_documentation token_owner: 'current_user'
      end
    end

    it 'evaluates the proc with the token owner' do
      expect(parameter_names('/search')).to eq(%w[query])
    end
  end

  context 'with body parameters' do
    let(:app) do
      Class.new(Grape::API) do
        format :json

        params do
          optional :query, type: String
          optional :filters, type: Hash, documentation: { hidden: true } do
            optional :status, type: String
          end
        end
        post('/search') { 'ok' }

        add_swagger_documentation
      end
    end

    it 'leaves no hidden children in the body definition' do
      get '/swagger_doc'
      json = JSON.parse(last_response.body)
      definition = json['definitions'].values.first
      expect(definition['properties'].keys).to eq(%w[query])
    end
  end
end
