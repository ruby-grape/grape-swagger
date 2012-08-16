require 'spec_helper'
describe "helpers" do

	before(:all) do
		class HelperTestAPI < Grape::API
			add_swagger_documentation
		end

		@api = Object.new
		# after injecting grape-swagger into the Test API we get the helper methods
		# back from the first endpoint's class (the API mounted by grape-swagger 
		# to serve the swagger_doc
		@api.extend HelperTestAPI.endpoints.first.options[:app].helpers

	end
	
	it "should parse params as query strings for a GET" do
		params = {
			name: {type: 'String', :desc =>"A name", required: true },
			level: 'max' 
		}
		path = "/coolness"
		method = "GET"
		@api.parse_params(params, path, method).should == 
		[	
			{paramType: "query", name: :name, description:"A name", dataType: "String", required: true},
			{paramType: "query", name: :level, description:"", dataType: "String", required: false}
		]
	end
	
	it "should parse params as body for a POST" do
		params = {
			name: {type: 'String', :desc =>"A name", required: true },
			level: 'max' 
		}
		path = "/coolness"
		method = "POST"
		@api.parse_params(params, path, method).should == 
		[	
			{paramType: "body", name: :name, description:"A name", dataType: "String", required: true},
			{paramType: "body", name: :level, description:"", dataType: "String", required: false}
		]
	end
	
end