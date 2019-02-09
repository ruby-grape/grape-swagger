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
