require 'spec_helper'

describe Grape::API do
  it 'added combined-routes' do
    expect(Grape::API).to respond_to :combined_routes
  end

  it 'added add_swagger_documentation' do
    expect(Grape::API).to respond_to :add_swagger_documentation
  end

  it 'added combined-namespaces' do
    expect(Grape::API).to respond_to :combined_namespaces
  end
end
