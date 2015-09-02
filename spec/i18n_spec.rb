require 'spec_helper'

describe 'I18n Default Translation' do
  module Entities
    class User < Grape::Entity
      expose :id, documentation: { type: String }
      expose :name, documentation: { type: String }
      expose :email, documentation: { type: String }
      expose :sign_up_at, documentation: { type: String }
    end

    class AdminUser < User
      expose :level, documentation: { type: Integer }
    end

    class PasswordStrength < Grape::Entity
      expose :level, documentation: { type: Integer }
      expose :crack_time, documentation: { type: Float }
    end
  end

  def app
    Class.new(Grape::API) do
      format :json

      params do
        optional :locale, type: Symbol
      end
      namespace :users do
        desc nil do
          success Entities::User
        end
        params do
          optional :sort, type: String
        end
        get do
          []
        end

        params do
          requires :id, type: String
        end
        route_param :id do
          desc '' do
            success Entities::AdminUser
          end
          get do
            {}
          end

          params do
            requires :email, type: String
          end
          put :email do
          end

          desc nil do
            success Entities::PasswordStrength
          end
          get :'password/strength' do
            {}
          end
        end
      end

      add_swagger_documentation
    end
  end

  def api_translations
    yaml_en = <<-EOS.strip_heredoc
      info:
        title: My Awesome API
        desc: Some detail information about this API.
      entities:
        default:
          id: Resource identifier
        user:
          name: User's real name
          email: User's login email address
          sign_up_at: When the user signed up
        admin_user:
          level: Which level the admin is
        password_strength:
          level: A 0~4 integer indicates `very_weak` to `strong`
          crack_time: An estimated time for force cracking the password, in seconds
      params:
        locale: Used to change locale of endpoint's responding message
        sort: To specify the order of result list
      users:
        desc: Operations about not-disabled users
        get:
          desc: Gets a list of users
          detail: You can control how to sort the results.
        ':id':
          params:
            id: User id
          get:
            desc: Finds user by id
          email:
            put:
              desc: Changes a user's email
              params:
                email: A new email
          password:
            strength:
              get:
                desc: Gets the strength estimation of a user's password
                detail: The estimation is done by a well-known algorithm when he changed his password
      swagger_doc:
        desc: Endpoints for API documents
        get:
          desc: Gets root API document
        ':name':
          get:
            desc: Gets specific resource API document
            params:
              name: Resource name
    EOS

    YAML.load(yaml_en)
  end

  context 'swagger_doc' do
    subject do
      with_translations :en, api: api_translations do
        get '/swagger_doc'
        JSON.parse(last_response.body).deep_symbolize_keys
      end
    end

    it 'translates api info' do
      expect(subject[:info]).to eq(
        title: 'My Awesome API',
        description: 'Some detail information about this API.'
      )
    end

    it 'translates root namespace description (including swagger_doc)' do
      expect(subject[:apis]).to eq [
        { path: '/users.{format}', description: 'Operations about not-disabled users' },
        { path: '/swagger_doc.{format}', description: 'Endpoints for API documents' }
      ]
    end
  end

  it 'translates endpoint description, notes and params' do
    result = with_translations :en, api: api_translations do
      get '/swagger_doc/users'
      JSON.parse(last_response.body).deep_symbolize_keys
    end

    api_index = 0
    expect(result[:apis][api_index][:operations][0]).to include(
      summary: 'Gets a list of users', notes: 'You can control how to sort the results.'
    )
    expect(result[:apis][api_index][:operations][0][:parameters]).to eq [
      { paramType: 'query', name: 'locale', description: "Used to change locale of endpoint's responding message", type: 'string', required: false, allowMultiple: false },
      { paramType: 'query', name: 'sort', description: 'To specify the order of result list', type: 'string', required: false, allowMultiple: false }
    ]

    api_index += 1
    expect(result[:apis][api_index][:operations][0]).to include(
      summary: 'Finds user by id', notes: ''
    )
    expect(result[:apis][api_index][:operations][0][:parameters]).to eq [
      { paramType: 'path', name: 'id', description: 'User id', type: 'string', required: true, allowMultiple: false },
      { paramType: 'query', name: 'locale', description: "Used to change locale of endpoint's responding message", type: 'string', required: false, allowMultiple: false }
    ]

    api_index += 1
    expect(result[:apis][api_index][:operations][0]).to include(
      summary: "Changes a user's email", notes: ''
    )
    expect(result[:apis][api_index][:operations][0][:parameters]).to eq [
      { paramType: 'path', name: 'id', description: 'User id', type: 'string', required: true, allowMultiple: false },
      { paramType: 'form', name: 'locale', description: "Used to change locale of endpoint's responding message", type: 'string', required: false, allowMultiple: false },
      { paramType: 'form', name: 'email', description: 'A new email', type: 'string', required: true, allowMultiple: false }
    ]

    api_index += 1
    expect(result[:apis][api_index][:operations][0]).to include(
      summary: "Gets the strength estimation of a user's password", notes: 'The estimation is done by a well-known algorithm when he changed his password'
    )
    expect(result[:apis][api_index][:operations][0][:parameters]).to eq [
      { paramType: 'path', name: 'id', description: 'User id', type: 'string', required: true, allowMultiple: false },
      { paramType: 'query', name: 'locale', description: "Used to change locale of endpoint's responding message", type: 'string', required: false, allowMultiple: false }
    ]
  end

  it 'translates swagger doc endpoints description, notes and params' do
    result = with_translations :en, api: api_translations do
      get '/swagger_doc/swagger_doc'
      JSON.parse(last_response.body).deep_symbolize_keys
    end

    api_index = 0
    expect(result[:apis][api_index][:operations][0]).to include(
      summary: 'Gets root API document'
    )
    expect(result[:apis][api_index][:operations][0][:parameters]).to eq [
      { paramType: 'query', name: 'locale', description: "Used to change locale of endpoint's responding message", type: 'string', required: false, allowMultiple: false }
    ]

    api_index += 1
    expect(result[:apis][api_index][:operations][0]).to include(
      summary: 'Gets specific resource API document'
    )
    expect(result[:apis][api_index][:operations][0][:parameters]).to eq [
      { paramType: 'path', name: 'name', description: 'Resource name', type: 'string', required: true, allowMultiple: false },
      { paramType: 'query', name: 'locale', description: "Used to change locale of endpoint's responding message", type: 'string', required: false, allowMultiple: false }
    ]
  end
end

describe 'I18n Customized Translation' do
  def api_translations
    yaml_en = <<-EOS.strip_heredoc
      info:
        title: My Awesome I18n API
        desc: Some details in English
      custom:
        api_info: My Custom Awesome API
      interpolation: My %{keyword} API
    EOS

    YAML.load(yaml_en)
  end

  def extra_translations
    yaml_en = <<-EOS.strip_heredoc
      info:
        title: My Awesome I18n API in Extra Scope
        desc: Some details in English in Extra Scope
      custom:
        api_info: My Custom Awesome API in Extra Scope
      interpolation: This API supports %{count} languages, and by default it is in %{language}.
    EOS

    YAML.load(yaml_en)
  end

  subject do
    with_translations :en, api: api_translations, extra: extra_translations do
      get '/swagger_doc'
      JSON.parse(last_response.body).deep_symbolize_keys
    end
  end

  context 'a string' do
    def app
      Class.new(Grape::API) do
        format :json
        add_swagger_documentation info: {
          title: 'My Plain API', description: 'Boring description', license: 'MIT License'
        }
      end
    end

    it 'became default message when translation missing' do
      expect(subject[:info]).to eq(
        title: 'My Awesome I18n API',
        description: 'Some details in English',
        license: 'MIT License'
      )
    end
  end

  context 'a symbol' do
    def app
      Class.new(Grape::API) do
        format :json
        add_swagger_documentation info: { title: :'custom.api_info', description: :missing }
      end
    end

    it 'acts as custom lookup key' do
      expect(subject[:info][:title]).to eq 'My Custom Awesome API'
    end

    it 'can fallback to default key' do
      expect(subject[:info][:description]).to eq 'Some details in English'
    end
  end

  context 'a hash' do
    context 'using :key and :default' do
      def app
        Class.new(Grape::API) do
          format :json
          add_swagger_documentation info: {
            title: { key: :'custom.api_info', default: 'A Demo API' },
            description: { key: :missing, default: 'No need to say anything more' },
            license: { key: :license, default: 'MIT License' }
          }
        end
      end

      it 'to define custom lookup key and default message together' do
        expect(subject[:info]).to eq(
          title: 'My Custom Awesome API',
          description: 'Some details in English',
          license: 'MIT License'
        )
      end
    end

    context 'using :translate with "false"' do
      def app
        Class.new(Grape::API) do
          format :json
          add_swagger_documentation info: {
            title: { default: 'A Demo API', translate: false },
            description: { translate: false }
          }
        end
      end

      it 'to skip translation' do
        expect(subject[:info]).to eq(
          title: 'A Demo API'
        )
      end
    end

    context 'using :scope' do
      def app
        Class.new(Grape::API) do
          format :json
          add_swagger_documentation info: {
            title: { key: :'custom.api_info', scope: :extra },
            description: { scope: 'extra' }
          }
        end
      end

      it 'to look up in custom scope' do
        expect(subject[:info]).to eq(
          title: 'My Custom Awesome API in Extra Scope',
          description: 'Some details in English in Extra Scope'
        )
      end
    end

    context 'all other params' do
      def app
        Class.new(Grape::API) do
          format :json
          add_swagger_documentation info: {
            title: { key: :interpolation, keyword: 'Best' },
            description: { key: :interpolation, scope: :extra, count: 2, language: 'English' }
          }
        end
      end

      it 'can be interpolated into the translation' do
        expect(subject[:info]).to eq(
          title: 'My Best API',
          description: 'This API supports 2 languages, and by default it is in English.'
        )
      end
    end
  end
end
