# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::Builder::ParserContext do
  # Contract with third-party model parsers, derived from the shipped ones:
  #   grape-swagger-entity   (Entity::Helper.model_name):  endpoint.send(:expose_params_from_model, model)
  #   grape-swagger-representable (Representable::Parser):  endpoint.send(:expose_params_from_model, representer)
  # Neither reads definitions or options from the endpoint; both only pass it through.
  it 'responds to every method shipped parsers call on the endpoint' do
    context = described_class.new { |model| "name_of_#{model}" }

    expect(context).to respond_to(:expose_params_from_model)
    expect(context.send(:expose_params_from_model, 'X')).to eq 'name_of_X'
  end

  describe 'integration with the OAS 3 builder' do
    before :all do
      module ParserContextSpec
        class Tag < Grape::Entity
          expose :label, documentation: { type: String }
        end

        class Post < Grape::Entity
          expose :title, documentation: { type: String }
          expose :tag, documentation: { type: Tag }
        end
      end
    end

    it 'does not touch the endpoint it builds for' do
      endpoint = Object.new

      builder = GrapeSwagger::OpenAPI::Builder::Spec.new(endpoint, Class.new(Grape::API), Rack::Request.new(Rack::MockRequest.env_for('/')),
                                                         openapi_version: '3.0.0', models: [ParserContextSpec::Post])
      builder.build({})

      expect(endpoint.instance_variables).to be_empty
      expect(builder.spec.components.schemas.keys).to include('ParserContextSpec_Tag')
    end
  end
end
