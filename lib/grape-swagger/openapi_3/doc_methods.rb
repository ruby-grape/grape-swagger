# frozen_string_literal: true

require 'grape-swagger/doc_methods/status_codes'
require 'grape-swagger/doc_methods/produces_consumes'
require 'grape-swagger/doc_methods/data_type'
require 'grape-swagger/doc_methods/extensions'
require 'grape-swagger/doc_methods/operation_id'
require 'grape-swagger/doc_methods/optional_object'
require 'grape-swagger/doc_methods/path_string'
require 'grape-swagger/doc_methods/tag_name_description'
require 'grape-swagger/openapi_3/doc_methods/parse_params'
require 'grape-swagger/openapi_3/doc_methods/move_params'
require 'grape-swagger/doc_methods/headers'
require 'grape-swagger/doc_methods/build_model_definition'
require 'grape-swagger/doc_methods/version'

module GrapeOpenAPI
  module DocMethods
    def hide_documentation_path
      @@hide_documentation_path
    end

    def mount_path
      @@mount_path
    end

    def setup(options)
      options = defaults.merge(options)

      # options could be set on #add_swagger_documentation call,
      # for available options see #defaults
      target_class     = options[:target_class]
      guard            = options[:swagger_endpoint_guard]
      formatter        = options[:format]
      api_doc          = options[:api_documentation].dup
      specific_api_doc = options[:specific_api_documentation].dup

      class_variables_from(options)

      if formatter
        %i[format default_format default_error_formatter].each do |method|
          send(method, formatter)
        end
      end

      desc api_doc.delete(:desc), api_doc

      instance_eval(guard) unless guard.nil?

      output_path_definitions = proc do |combi_routes, endpoint|
        output = endpoint.swagger_object(
          target_class,
          endpoint.request,
          options
        )

        paths, definitions   = endpoint.path_and_definition_objects(combi_routes, target_class, options)
        tags                 = tags_from(paths, options)

        output[:tags]        = tags unless tags.empty? || paths.blank?
        output[:paths]       = paths unless paths.blank?
        unless definitions.blank?
          output[:components] ||= {}
          output[:components][:schemas] = definitions
        end

        output
      end

      get mount_path do
        header['Access-Control-Allow-Origin']   = '*'
        header['Access-Control-Request-Method'] = '*'

        output_path_definitions.call(target_class.combined_namespace_routes, self)
      end

      desc specific_api_doc.delete(:desc), { params:
        specific_api_doc.delete(:params) || {} }.merge(specific_api_doc)

      params do
        requires :name, type: String, desc: 'Resource name of mounted API'
        optional :locale, type: Symbol, desc: 'Locale of API documentation'
      end

      get "#{mount_path}/:name" do
        I18n.locale = params[:locale] || I18n.default_locale

        combined_routes = target_class.combined_namespace_routes[params[:name]]
        error!({ error: 'named resource not exist' }, 400) if combined_routes.nil?

        output_path_definitions.call({ params[:name] => combined_routes }, self)
      end
    end

    def defaults
      {
        info: {},
        models: [],
        doc_version: '0.0.1',
        target_class: nil,
        mount_path: '/swagger_doc',
        host: nil,
        base_path: nil,
        add_base_path: false,
        add_version: true,
        hide_documentation_path: true,
        format: :json,
        authorizations: nil,
        security_definitions: nil,
        security: nil,
        api_documentation: { desc: 'Swagger compatible API description' },
        specific_api_documentation: { desc: 'Swagger compatible API description for specific API' },
        endpoint_auth_wrapper: nil,
        swagger_endpoint_guard: nil,
        token_owner: nil
      }
    end

    def class_variables_from(options)
      @@mount_path              = options[:mount_path]
      @@class_name              = options[:class_name] || options[:mount_path].delete('/')
      @@hide_documentation_path = options[:hide_documentation_path]
    end

    def tags_from(paths, options)
      tags = GrapeSwagger::DocMethods::TagNameDescription.build(paths)

      if options[:tags]
        names = options[:tags].map { |t| t[:name] }
        tags.reject! { |t| names.include?(t[:name]) }
        tags += options[:tags]
      end

      tags
    end
  end
end
