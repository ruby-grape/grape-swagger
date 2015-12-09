require 'spec_helper'

describe 'Group Params as Hash' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :required_group, type: Hash do
          requires :required_param_1
          requires :required_param_2
        end
      end
      post '/groups' do
        { 'declared_params' => declared(params) }
      end

      params do
        requires :typed_group, type: Hash do
          requires :id, type: Integer, desc: "integer given"
          requires :name, type: String, desc: "string given"
          optional :email, type: String, desc: "email given"
          optional :others, type: Integer, values: [1, 2, 3]
        end
      end
      post '/type_given' do
        { 'declared_params' => declared(params) }
      end

      add_swagger_documentation
    end
  end

  it 'retrieves the documentation for group parameters' do
    get '/swagger_doc/groups'
    body = JSON.parse last_response.body
    expect(body).to eql({
      "info"=>{"title"=>"API title", "version"=>"v1"},
      "swagger"=>"2.0",
      "produces"=>["application/json"],
      "host"=>"example.org",
      "schemes" => ["https", "http"],
      "paths"=>{
        "/groups"=>{
          "post"=>{
            "produces"=>["application/json"],
            "responses"=>{"201"=>{"description"=>"created Group"}},
            "parameters"=>[
              {"in"=>"formData", "name"=>"required_group[required_param_1]", "description"=>nil, "type"=>"string", "required"=>true, "allowMultiple"=>false},
              {"in"=>"formData", "name"=>"required_group[required_param_2]", "description"=>nil, "type"=>"string", "required"=>true, "allowMultiple"=>false}
            ]}}}}
    )
  end

  it 'retrieves the documentation for group parameters' do
    get '/swagger_doc/type_given'
    body = JSON.parse last_response.body
    expect(body).to eql({
      "info"=>{"title"=>"API title", "version"=>"v1"},
      "swagger"=>"2.0",
      "produces"=>["application/json"],
      "host"=>"example.org",
      "schemes" => ["https", "http"],
      "paths"=>{
        "/type_given"=>{
          "post"=>{
            "produces"=>["application/json"],
            "responses"=>{"201"=>{"description"=>"created TypeGiven"}},
            "parameters"=>[
              {"in"=>"formData", "name"=>"typed_group[id]", "description"=>"integer given", "type"=>"integer", "required"=>true, "allowMultiple"=>false, "format"=>"int32"},
              {"in"=>"formData", "name"=>"typed_group[name]", "description"=>"string given", "type"=>"string", "required"=>true, "allowMultiple"=>false},
              {"in"=>"formData", "name"=>"typed_group[email]", "description"=>"email given", "type"=>"string", "required"=>false, "allowMultiple"=>false},
              {"in"=>"formData", "name"=>"typed_group[others]", "description"=>nil, "type"=>"integer", "required"=>false, "allowMultiple"=>false, "format"=>"int32", "enum"=>[1, 2, 3]}
            ]}}}}
    )
  end

end
