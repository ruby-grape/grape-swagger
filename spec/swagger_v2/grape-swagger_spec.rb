# frozen_string_literal: true

require 'spec_helper'

describe GrapeInstance do
  it 'added combined-routes' do
    expect(described_class).to respond_to :combined_routes
  end

  it 'added add_swagger_documentation' do
    expect(described_class).to respond_to :add_swagger_documentation
  end

  it 'added combined-namespaces' do
    expect(described_class).to respond_to :combined_namespaces
  end
end

describe 'top-level compatibility aliases' do
  it 'keeps SwaggerRouting available at the top level' do
    expect(SwaggerRouting).to equal(GrapeSwagger::SwaggerRouting)
  end

  it 'keeps SwaggerDocumentationAdder available at the top level' do
    expect(SwaggerDocumentationAdder).to equal(GrapeSwagger::SwaggerDocumentationAdder)
  end
end
