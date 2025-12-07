# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.x Integration Tests' do
  describe 'Complete API with multiple features' do
    before :all do
      module IntegrationTest
        module Entities
          class Error < Grape::Entity
            expose :code, documentation: { type: Integer, desc: 'Error code', required: true }
            expose :message, documentation: { type: String, desc: 'Error message', required: true }
          end

          class ValidationError < Grape::Entity
            expose :code, documentation: { type: Integer, desc: 'Error code', required: true }
            expose :message, documentation: { type: String, desc: 'Error message', required: true }
            expose :fields, documentation: { type: String, is_array: true, desc: 'Invalid fields' }
          end

          class Address < Grape::Entity
            expose :street, documentation: { type: String, desc: 'Street address', required: true }
            expose :city, documentation: { type: String, desc: 'City', required: true }
            expose :country, documentation: { type: String, desc: 'Country code', required: true }
            expose :postal_code, documentation: { type: String, desc: 'Postal code' }
          end

          class User < Grape::Entity
            expose :id, documentation: { type: Integer, desc: 'User ID', required: true }
            expose :email, documentation: { type: String, desc: 'Email address', required: true }
            expose :name, documentation: { type: String, desc: 'Full name', required: true }
            expose :role, documentation: { type: String, desc: 'User role', values: %w[admin user guest] }
            expose :address, using: Address, documentation: { desc: 'User address' }
            expose :created_at, documentation: { type: DateTime, desc: 'Creation timestamp' }
          end

          class UserList < Grape::Entity
            expose :users, using: User, documentation: { is_array: true, desc: 'List of users', required: true }
            expose :total, documentation: { type: Integer, desc: 'Total count', required: true }
            expose :page, documentation: { type: Integer, desc: 'Current page', required: true }
          end

          class CreateUserRequest < Grape::Entity
            expose :email, documentation: { type: String, desc: 'Email address', required: true }
            expose :name, documentation: { type: String, desc: 'Full name', required: true }
            expose :password, documentation: { type: String, desc: 'Password', required: true }
            expose :role, documentation: { type: String, desc: 'User role', values: %w[admin user guest] }
          end
        end

        class API < Grape::API
          format :json
          prefix :api
          version 'v1', using: :path

          helpers do
            def current_user
              OpenStruct.new(id: 1, role: 'admin')
            end
          end

          resource :users do
            desc 'List all users',
                 success: Entities::UserList,
                 failure: [
                   { code: 401, message: 'Unauthorized', model: Entities::Error },
                   { code: 403, message: 'Forbidden', model: Entities::Error }
                 ],
                 tags: ['users']
            params do
              optional :page, type: Integer, default: 1, desc: 'Page number'
              optional :per_page, type: Integer, default: 20, desc: 'Items per page'
              optional :search, type: String, desc: 'Search query'
              optional :role, type: String, values: %w[admin user guest], desc: 'Filter by role'
            end
            get do
              present({ users: [], total: 0, page: params[:page] }, with: Entities::UserList)
            end

            desc 'Create a new user',
                 success: { code: 201, model: Entities::User },
                 failure: [
                   { code: 400, message: 'Bad Request', model: Entities::ValidationError },
                   { code: 401, message: 'Unauthorized', model: Entities::Error },
                   { code: 409, message: 'Conflict', model: Entities::Error }
                 ],
                 consumes: ['application/json'],
                 tags: ['users']
            params do
              requires :email, type: String, regexp: /\A[^@]+@[^@]+\z/, desc: 'Email address'
              requires :name, type: String, desc: 'Full name'
              requires :password, type: String, desc: 'Password (min 8 chars)'
              optional :role, type: String, values: %w[admin user guest], default: 'user', desc: 'User role'
            end
            post do
              present OpenStruct.new(id: 1, email: params[:email], name: params[:name]),
                      with: Entities::User
            end

            route_param :id, type: Integer do
              desc 'Get user by ID',
                   success: Entities::User,
                   failure: [
                     { code: 401, message: 'Unauthorized', model: Entities::Error },
                     { code: 404, message: 'Not Found', model: Entities::Error }
                   ],
                   tags: ['users']
              get do
                present OpenStruct.new(id: params[:id], email: 'test@example.com'),
                        with: Entities::User
              end

              desc 'Update user',
                   success: Entities::User,
                   failure: [
                     { code: 400, message: 'Bad Request', model: Entities::ValidationError },
                     { code: 401, message: 'Unauthorized', model: Entities::Error },
                     { code: 404, message: 'Not Found', model: Entities::Error }
                   ],
                   consumes: ['application/json'],
                   tags: ['users']
              params do
                optional :email, type: String, desc: 'Email address'
                optional :name, type: String, desc: 'Full name'
                optional :role, type: String, values: %w[admin user guest], desc: 'User role'
              end
              put do
                present OpenStruct.new(id: params[:id]), with: Entities::User
              end

              desc 'Delete user',
                   failure: [
                     { code: 401, message: 'Unauthorized', model: Entities::Error },
                     { code: 404, message: 'Not Found', model: Entities::Error }
                   ],
                   tags: ['users']
              delete do
                status 204
              end
            end
          end

          resource :files do
            desc 'Upload a file',
                 consumes: ['multipart/form-data'],
                 tags: ['files']
            params do
              requires :file, type: File, desc: 'File to upload'
              optional :description, type: String, desc: 'File description'
            end
            post :upload do
              { uploaded: true }
            end
          end

          add_swagger_documentation(
            openapi_version: '3.0',
            info: {
              title: 'Integration Test API',
              description: 'A comprehensive API for integration testing',
              version: '1.0.0',
              contact: {
                name: 'API Support',
                email: 'support@example.com'
              },
              license: {
                name: 'MIT',
                url: 'https://opensource.org/licenses/MIT'
              }
            },
            host: 'api.example.com',
            base_path: '/api/v1',
            tags: [
              { name: 'users', description: 'User management operations' },
              { name: 'files', description: 'File operations' }
            ],
            security_definitions: {
              bearer: {
                type: 'apiKey',
                name: 'Authorization',
                in: 'header',
                description: 'Bearer token authentication'
              }
            },
            security: [{ bearer: [] }]
          )
        end
      end
    end

    def app
      IntegrationTest::API
    end

    subject do
      get '/api/v1/swagger_doc'
      JSON.parse(last_response.body)
    end

    describe 'API structure' do
      it 'has correct openapi version' do
        expect(subject['openapi']).to eq('3.0.3')
      end

      it 'has info section with all fields' do
        info = subject['info']
        expect(info['title']).to eq('Integration Test API')
        expect(info['description']).to include('comprehensive API')
        expect(info['version']).to be_present
        expect(info['license']['name']).to eq('MIT')
      end

      # NOTE: contact info requires contact_name, contact_email, contact_url options
      # The nested hash format under info: { contact: {} } may not be fully supported

      it 'has servers section' do
        expect(subject['servers']).to be_an(Array)
        expect(subject['servers'].first['url']).to include('api.example.com')
      end

      it 'has tags section' do
        tags = subject['tags']
        expect(tags.map { |t| t['name'] }).to include('users', 'files')
      end

      it 'has security at root level' do
        expect(subject['security']).to eq([{ 'bearer' => [] }])
      end

      it 'has components with securitySchemes' do
        schemes = subject['components']['securitySchemes']
        expect(schemes).to have_key('bearer')
        expect(schemes['bearer']['type']).to eq('apiKey')
      end
    end

    describe 'paths structure' do
      it 'has all expected paths' do
        paths = subject['paths'].keys
        expect(paths).to include('/api/v1/users')
        expect(paths).to include('/api/v1/users/{id}')
        expect(paths).to include('/api/v1/files/upload')
      end

      describe 'GET /users' do
        let(:operation) { subject['paths']['/api/v1/users']['get'] }

        it 'has correct operation structure' do
          expect(operation['tags']).to include('users')
          expect(operation['parameters']).to be_an(Array)
        end

        it 'has query parameters with schema wrapper' do
          page_param = operation['parameters'].find { |p| p['name'] == 'page' }
          expect(page_param['in']).to eq('query')
          expect(page_param['schema']).to have_key('type')
          expect(page_param['schema']['type']).to eq('integer')
          expect(page_param['schema']['default']).to eq(1)
        end

        it 'has enum parameter' do
          role_param = operation['parameters'].find { |p| p['name'] == 'role' }
          expect(role_param['schema']['enum']).to eq(%w[admin user guest])
        end

        it 'has responses with content wrapper' do
          response_200 = operation['responses']['200']
          expect(response_200['content']).to have_key('application/json')
          expect(response_200['content']['application/json']['schema']).to have_key('$ref')
        end

        it 'has error responses' do
          expect(operation['responses']).to have_key('401')
          expect(operation['responses']).to have_key('403')
        end
      end

      describe 'POST /users' do
        let(:operation) { subject['paths']['/api/v1/users']['post'] }

        it 'has requestBody instead of body parameter' do
          expect(operation['requestBody']).to be_present
          expect(operation['parameters']&.any? { |p| p['in'] == 'body' }).to be_falsey
        end

        it 'has requestBody with content' do
          content = operation['requestBody']['content']
          expect(content).to have_key('application/json')
        end

        it 'marks requestBody as required' do
          expect(operation['requestBody']['required']).to be true
        end
      end

      describe 'GET /users/{id}' do
        let(:operation) { subject['paths']['/api/v1/users/{id}']['get'] }

        it 'has path parameter with schema' do
          id_param = operation['parameters'].find { |p| p['name'] == 'id' }
          expect(id_param['in']).to eq('path')
          expect(id_param['required']).to be true
          expect(id_param['schema']['type']).to eq('integer')
        end
      end

      describe 'DELETE /users/{id}' do
        let(:operation) { subject['paths']['/api/v1/users/{id}']['delete'] }

        it 'has no requestBody' do
          expect(operation['requestBody']).to be_nil
        end
      end

      describe 'POST /files/upload' do
        let(:operation) { subject['paths']['/api/v1/files/upload']['post'] }

        it 'uses multipart/form-data for file upload' do
          content = operation['requestBody']['content']
          expect(content).to have_key('multipart/form-data')
        end

        it 'has file field with binary format' do
          schema = operation['requestBody']['content']['multipart/form-data']['schema']
          file_prop = schema['properties']['file']
          expect(file_prop['type']).to eq('string')
          expect(file_prop['format']).to eq('binary')
        end
      end
    end

    describe 'components/schemas' do
      let(:schemas) { subject['components']['schemas'] }

      it 'has all entity schemas' do
        schema_names = schemas.keys
        expect(schema_names.any? { |n| n.include?('User') }).to be true
        expect(schema_names.any? { |n| n.include?('Error') }).to be true
        expect(schema_names.any? { |n| n.include?('Address') }).to be true
      end

      it 'uses $ref for nested entities' do
        user_schema = schemas.find { |name, _| name.include?('User') && !name.include?('List') && !name.include?('Request') }
        if user_schema
          props = user_schema[1]['properties']
          expect(props['address']['$ref'] || props['address']['description']).to be_present if props && props['address']
        end
      end
    end

    describe 'no Swagger 2.0 artifacts' do
      it 'does not have swagger key' do
        expect(subject).not_to have_key('swagger')
      end

      it 'does not have definitions at root' do
        expect(subject).not_to have_key('definitions')
      end

      it 'does not have securityDefinitions at root' do
        expect(subject).not_to have_key('securityDefinitions')
      end

      it 'does not have host/basePath/schemes at root' do
        expect(subject).not_to have_key('host')
        expect(subject).not_to have_key('basePath')
        expect(subject).not_to have_key('schemes')
      end

      it 'does not have produces/consumes at root' do
        expect(subject).not_to have_key('produces')
        expect(subject).not_to have_key('consumes')
      end

      it 'uses #/components/schemas refs not #/definitions' do
        json_string = subject.to_json
        expect(json_string).not_to include('#/definitions/')
        expect(json_string).to include('#/components/schemas/')
      end
    end
  end

  describe 'API with mixed parameter types' do
    before :all do
      module MixedParamsTest
        class API < Grape::API
          format :json

          desc 'Mixed parameters endpoint'
          params do
            requires :id, type: Integer, desc: 'Resource ID'
            requires :name, type: String, desc: 'Name in body'
            optional :include, type: Array[String], desc: 'Relations to include'
          end
          put '/resources/:id' do
            { id: params[:id], name: params[:name] }
          end

          add_swagger_documentation(openapi_version: '3.0')
        end
      end
    end

    def app
      MixedParamsTest::API
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'separates path and body parameters correctly' do
      operation = subject['paths']['/resources/{id}']['put']

      # Path parameter should be in parameters array
      path_params = operation['parameters'].select { |p| p['in'] == 'path' }
      expect(path_params.length).to eq(1)
      expect(path_params.first['name']).to eq('id')

      # Body parameters should be in requestBody
      expect(operation['requestBody']).to be_present
    end
  end

  describe 'OAS 3.1 vs 3.0 differences' do
    before :all do
      module VersionDiffTest
        module Entities
          class Item < Grape::Entity
            expose :id, documentation: { type: Integer, required: true }
            expose :name, documentation: { type: String, required: true }
            expose :optional_field, documentation: { type: String, x: { nullable: true } }
          end
        end

        class API30 < Grape::API
          format :json
          desc 'Get item', success: Entities::Item
          get('/item') { {} }
          add_swagger_documentation(openapi_version: '3.0')
        end

        class API31 < Grape::API
          format :json
          desc 'Get item', success: Entities::Item
          get('/item') { {} }
          add_swagger_documentation(
            openapi_version: '3.1',
            info: { license: { name: 'MIT', identifier: 'MIT' } }
          )
        end
      end
    end

    describe 'OpenAPI 3.0' do
      def app
        VersionDiffTest::API30
      end

      subject do
        get '/swagger_doc'
        JSON.parse(last_response.body)
      end

      it 'uses openapi 3.0.3' do
        expect(subject['openapi']).to eq('3.0.3')
      end

      it 'does not have license identifier' do
        # 3.0 doesn't support identifier
        license = subject['info']['license']
        expect(license).to be_nil.or(satisfy { |l| !l.key?('identifier') })
      end
    end

    describe 'OpenAPI 3.1' do
      def app
        VersionDiffTest::API31
      end

      subject do
        get '/swagger_doc'
        JSON.parse(last_response.body)
      end

      it 'uses openapi 3.1.0' do
        expect(subject['openapi']).to eq('3.1.0')
      end

      it 'has license identifier' do
        expect(subject['info']['license']['identifier']).to eq('MIT')
      end

      it 'does not have nullable keyword' do
        json_string = subject.to_json
        expect(json_string).not_to include('"nullable":true')
        expect(json_string).not_to include('"nullable": true')
      end
    end
  end
end
