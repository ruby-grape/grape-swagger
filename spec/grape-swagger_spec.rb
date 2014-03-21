require 'spec_helper'

describe Grape::API do

  it "added combined-routes" do
    Grape::API.should respond_to :combined_routes
  end

  it "added combined-namespaces" do
    Grape::API.should respond_to :combined_namespaces
  end

  it "added add_swagger_documentation" do
    Grape::API.should respond_to :add_swagger_documentation
  end

end
