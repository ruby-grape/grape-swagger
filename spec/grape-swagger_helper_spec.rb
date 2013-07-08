require 'spec_helper'

describe "helpers" do

  before :all do
    class HelperTestAPI < Grape::API
      add_swagger_documentation
    end
  end

  before :each do
    @api = Object.new

    # after injecting grape-swagger into the Test API we get the helper methods
    # back from the first endpoint's class (the API mounted by grape-swagger
    # to serve the swagger_doc

    @api.extend HelperTestAPI.endpoints.first.options[:app].helpers
  end

  context "parsing parameters" do
    before do
      @params = {
        name: { type: 'String', desc: "A name", required: true },
        level: 'max'
      }
      @path = "/coolness"
    end

    it "parses params as query strings for a GET" do
      method = "GET"
      @api.parse_params(@params, @path, method, nil).should == [
        { paramType: "query", name: :name, description: "A name", dataType: "String", required: true },
        { paramType: "query", name: :level, description: "", dataType: "String", required: false }
      ]
    end

    it "parses params as form for a POST" do
      method = "POST"
      @api.parse_params(@params, @path, method, nil).should == [
        { paramType: "form", name: :name, description: "A name", dataType: "String", required: true },
        { paramType: "form", name: :level, description: "", dataType: "String", required: false }
      ]
    end

    it "parses params as body with explicit option" do
      method = "POST"
      @api.parse_params(@params, @path, method, true).should == [
        { paramType: "body", name: :body, description: "", dataType: "String", required: true }
      ]
    end

    it "parses specific params as body if body_param is an array" do
      method = "POST"
      @api.parse_params(@params, @path, method, [:level]).should == [
        { paramType: "form", name: :name, description: "A name", dataType: "String", required: true },
        { paramType: "body", name: :body, description: "", dataType: "String", required: true }
      ]
    end

    it "does not include path params in body" do
      method = "FOO"
      @api.parse_params(@params, "/:level", method, true).should == [
        { paramType: "path", name: :level, description: "", dataType: "String", required: false },
        { paramType: "body", name: :body, description: "", dataType: "String", required: true }
      ]
    end

    it "body param does not require any parameters to be defined" do
      method = "FOO"
      @api.parse_params(nil, @path, method, true).should == [
        { paramType: "body", name: :body, description: "", dataType: "String", required: true }
      ]
    end
  end

  context "parsing the path" do
    it "parses the path" do
      path = ":abc/def(.:format)"
      @api.parse_path(path, nil).should == "{abc}/def.{format}"
    end

    it "parses a path that has vars with underscores in the name" do
      path = "abc/:def_g(.:format)"
      @api.parse_path(path, nil).should == "abc/{def_g}.{format}"
    end

    it "parses a path that has vars with numbers in the name" do
      path = "abc/:sha1(.:format)"
      @api.parse_path(path, nil).should == "abc/{sha1}.{format}"
    end

    it "parses a path that has multiple variables" do
      path1 = "abc/:def/:geh(.:format)"
      path2 = "abc/:def:geh(.:format)"
      @api.parse_path(path1, nil).should == "abc/{def}/{geh}.{format}"
      @api.parse_path(path2, nil).should == "abc/{def}{geh}.{format}"
    end

    it "parses the path with a specified version" do
      path = ":abc/{version}/def(.:format)"
      @api.parse_path(path, 'v1').should == "{abc}/v1/def.{format}"
    end
  end

  context "parsing header parameters" do
    it "parses params for the header" do
      params = {
        "XAuthToken" => { description: "A required header.", required: true }
      }
      @api.parse_header_params(params).should == [
        { paramType: "header", name: "XAuthToken", description: "A required header.", dataType: "String", required: true }
      ]
    end
  end

end
