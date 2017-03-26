# frozen_string_literal: true

require 'spec_helper'

describe 'setting of param type, such as `query`, `path`, `formData`, `body`, `header`' do
  include_context "#{MODEL_PARSER} swagger example"

  before :all do
    module TheApi
      class ParamTypeApi < Grape::API
        # using `:param_type`
        desc 'full set of request param types',
             success: Entities::UseResponse
        params do
          optional :in_query, type: String, documentation: { param_type: 'query' }
          optional :in_header, type: String, documentation: { param_type: 'header' }
        end

        get '/defined_param_type' do
          { 'declared_params' => declared(params) }
        end

        desc 'full set of request param types',
             success: Entities::UseResponse
        params do
          requires :in_path, type: Integer
          optional :in_query, type: String, documentation: { param_type: 'query' }
          optional :in_header, type: String, documentation: { param_type: 'header' }
        end

        get '/defined_param_type/:in_path' do
          { 'declared_params' => declared(params) }
        end

        desc 'full set of request param types',
             success: Entities::UseResponse
        params do
          optional :in_path, type: Integer
          optional :in_query, type: String, documentation: { param_type: 'query' }
          optional :in_header, type: String, documentation: { param_type: 'header' }
        end

        delete '/defined_param_type/:in_path' do
          { 'declared_params' => declared(params) }
        end

        # using `:in`
        desc 'full set of request param types using `:in`',
             success: Entities::UseResponse
        params do
          optional :in_query, type: String, documentation: { in: 'query' }
          optional :in_header, type: String, documentation: { in: 'header' }
        end

        get '/defined_in' do
          { 'declared_params' => declared(params) }
        end

        desc 'full set of request param types using `:in`',
             success: Entities::UseResponse
        params do
          requires :in_path, type: Integer
          optional :in_query, type: String, documentation: { in: 'query' }
          optional :in_header, type: String, documentation: { in: 'header' }
        end

        get '/defined_in/:in_path' do
          { 'declared_params' => declared(params) }
        end

        desc 'full set of request param types using `:in`'
        params do
          optional :in_path, type: Integer
          optional :in_query, type: String, documentation: { in: 'query' }
          optional :in_header, type: String, documentation: { in: 'header' }
        end

        delete '/defined_in/:in_path' do
          { 'declared_params' => declared(params) }
        end

        # file
        desc 'file download',
             success: Entities::UseResponse
        params do
          requires :name, type: String
        end

        get '/download' do
          { 'declared_params' => declared(params) }
        end

        desc 'file upload',
             success: Entities::UseResponse
        params do
          requires :name, type: File
        end

        post '/upload' do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation
      end
    end
  end

  def app
    TheApi::ParamTypeApi
  end

  describe 'foo' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/defined_param_type/{in_path}']['delete']['responses']).to eql(
        '200' => {
          'description' => 'full set of request param types',
          'schema' => { '$ref' => '#/definitions/UseResponse' }
        }
      )
    end

    specify do
      expect(subject['paths']['/defined_in/{in_path}']['delete']['responses']).to eql(
        '204' => {
          'description' => 'full set of request param types using `:in`'
        }
      )
    end
  end

  describe 'defined param types' do
    subject do
      get '/swagger_doc/defined_param_type'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/defined_param_type']['get']['parameters']).to eql(
        [
          { 'in' => 'query', 'name' => 'in_query', 'required' => false, 'type' => 'string' },
          { 'in' => 'header', 'name' => 'in_header', 'required' => false, 'type' => 'string' }
        ]
      )
    end

    specify do
      expect(subject['paths']['/defined_param_type/{in_path}']['get']['parameters']).to eql(
        [
          { 'in' => 'path', 'name' => 'in_path', 'required' => true, 'type' => 'integer', 'format' => 'int32' },
          { 'in' => 'query', 'name' => 'in_query', 'required' => false, 'type' => 'string' },
          { 'in' => 'header', 'name' => 'in_header', 'required' => false, 'type' => 'string' }
        ]
      )
    end

    specify do
      expect(subject['paths']['/defined_param_type/{in_path}']['delete']['parameters']).to eql(
        [
          { 'in' => 'path', 'name' => 'in_path', 'required' => true, 'type' => 'integer', 'format' => 'int32' },
          { 'in' => 'query', 'name' => 'in_query', 'required' => false, 'type' => 'string' },
          { 'in' => 'header', 'name' => 'in_header', 'required' => false, 'type' => 'string' }
        ]
      )
    end
  end

  describe 'defined param types with `:in`' do
    subject do
      get '/swagger_doc/defined_in'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/defined_in']['get']['parameters']).to eql(
        [
          { 'in' => 'query', 'name' => 'in_query', 'required' => false, 'type' => 'string' },
          { 'in' => 'header', 'name' => 'in_header', 'required' => false, 'type' => 'string' }
        ]
      )
    end

    specify do
      expect(subject['paths']['/defined_in/{in_path}']['get']['parameters']).to eql(
        [
          { 'in' => 'path', 'name' => 'in_path', 'required' => true, 'type' => 'integer', 'format' => 'int32' },
          { 'in' => 'query', 'name' => 'in_query', 'required' => false, 'type' => 'string' },
          { 'in' => 'header', 'name' => 'in_header', 'required' => false, 'type' => 'string' }
        ]
      )
    end

    specify do
      expect(subject['paths']['/defined_in/{in_path}']['delete']['parameters']).to eql(
        [
          { 'in' => 'path', 'name' => 'in_path', 'required' => true, 'type' => 'integer', 'format' => 'int32' },
          { 'in' => 'query', 'name' => 'in_query', 'required' => false, 'type' => 'string' },
          { 'in' => 'header', 'name' => 'in_header', 'required' => false, 'type' => 'string' }
        ]
      )
    end
  end

  describe 'file' do
    describe 'upload' do
      subject do
        get '/swagger_doc/upload'
        JSON.parse(last_response.body)
      end

      specify do
        expect(subject['paths']['/upload']['post']['parameters']).to eql(
          [
            { 'in' => 'formData', 'name' => 'name', 'required' => true, 'type' => 'file' }
          ]
        )
      end
    end

    describe 'download' do
      subject do
        get '/swagger_doc/download'
        JSON.parse(last_response.body)
      end

      specify do
        expect(subject['paths']['/download']['get']['parameters']).to eql(
          [
            { 'in' => 'query', 'name' => 'name', 'required' => true, 'type' => 'string' }
          ]
        )
      end
    end
  end
end
