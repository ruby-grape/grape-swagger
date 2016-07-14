require 'spec_helper'

describe 'setting of param collectionFormat, such as `csv`, `ssv`, `tsv`, `pipes`, `multi`' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class ParamCollectionFormatApi < Grape::API
        # All formats work in query. DRY SPEC
        %w(csv tsv ssv pipes multi).each do |format|
          parameter_key = "#{format}_parameter".to_sym
          desc "#{format} string array in query",
               success: Entities::UseResponse
          params do
            optional parameter_key, type: Array[String], documentation: { param_type: 'query', collection_format: format }
          end
          get "/#{format}_string_array_in_query" do
            { 'declared_params' => declared(params) }
          end

          desc "#{format} string no array",
               success: Entities::UseResponse
          params do
            optional parameter_key, type: String, documentation: { param_type: 'query', collection_format: format }
          end
          get "/#{format}_string_no_array" do
            { 'declared_params' => declared(params) }
          end
        end

        # ignore collection_format of multi unless parameter in formData or query
        desc 'multi string array in header - ignore',
             success: Entities::UseResponse
        params do
          optional :multi_string_array_in_header, type: Array[String], documentation: { param_type: 'header', collection_format: 'multi' }
        end
        get '/multi_string_array_in_header' do
          { 'declared_params' => declared(params) }
        end

        desc 'multi string array in formData',
             success: Entities::UseResponse
        params do
          optional :multi_string_array_in_form_data, type: Array[String], documentation: { param_type: 'formData', collection_format: 'multi' }
        end
        get '/multi_string_array_in_form_data' do
          { 'declared_params' => declared(params) }
        end

        desc 'invalid collectionFormat',
             success: Entities::UseResponse
        params do
          optional :invalid_string_array_in_query, type: Array[String], documentation: { param_type: 'formData', collection_format: 'invalid' }
        end
        get '/invalid_string_array_in_query' do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::ParamCollectionFormatApi
  end

  describe 'foo' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/multi_string_array_in_query']['get']['responses']).to eql(
        '200' => {
          'description' => 'multi string array in query',
          'schema' => { '$ref' => '#/definitions/UseResponse' }
        }
      )
    end
  end

  describe 'defined collectionFormat' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    %w(csv tsv ssv pipes multi).each do |format|
      describe format do
        specify do
          expect(subject['paths']["/#{format}_string_array_in_query"]['get']['parameters']).to eql(
            [
              { 'collectionFormat' => format, 'in' => 'query', 'name' => "#{format}_parameter", 'required' => false, 'type' => 'array', 'items' => { 'type' => 'string' } }
            ]
          )
        end

        specify do
          expect(subject['paths']["/#{format}_string_no_array"]['get']['parameters']).to eql(
            [
              { 'in' => 'query', 'name' => "#{format}_parameter", 'required' => false, 'type' => 'string' }
            ]
          )
        end
      end
    end

    describe 'multi specific' do
      specify do
        expect(subject['paths']['/multi_string_array_in_form_data']['get']['parameters']).to eql(
          [
            { 'collectionFormat' => 'multi', 'in' => 'formData', 'name' => 'multi_string_array_in_form_data', 'required' => false, 'type' => 'array', 'items' => { 'type' => 'string' } }
          ]
        )
      end

      specify do
        expect(subject['paths']['/multi_string_array_in_header']['get']['parameters']).to eql(
          [
            { 'in' => 'header', 'name' => 'multi_string_array_in_header', 'required' => false, 'type' => 'array', 'items' => { 'type' => 'string' } }
          ]
        )
      end
    end

    describe 'invalid' do
      specify do
        expect(subject['paths']['/invalid_string_array_in_query']['get']['parameters']).to eql(
          [
            { 'in' => 'formData', 'name' => 'invalid_string_array_in_query', 'required' => false, 'type' => 'array', 'items' => { 'type' => 'string' } }
          ]
        )
      end
    end
  end
end
