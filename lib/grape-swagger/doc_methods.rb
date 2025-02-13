# frozen_string_literal: true

require 'grape-swagger/doc_methods/status_codes'
require 'grape-swagger/doc_methods/produces_consumes'
require 'grape-swagger/doc_methods/data_type'
require 'grape-swagger/doc_methods/extensions'
require 'grape-swagger/doc_methods/format_data'
require 'grape-swagger/doc_methods/operation_id'
require 'grape-swagger/doc_methods/optional_object'
require 'grape-swagger/doc_methods/path_string'
require 'grape-swagger/doc_methods/tag_name_description'
require 'grape-swagger/doc_methods/parse_params'
require 'grape-swagger/doc_methods/move_params'
require 'grape-swagger/doc_methods/build_model_definition'
require 'grape-swagger/doc_methods/version'

module GrapeSwagger
  module DocMethods
    DEFAULTS =
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
        add_root: false,
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
      }.freeze

    FORMATTER_METHOD = %i[format default_format default_error_formatter].freeze

    def self.output_path_definitions(combi_routes, endpoint, target_class, options)
      output = endpoint.swagger_object(
        target_class,
        endpoint.request,
        options
      )

      paths, definitions   = endpoint.path_and_definition_objects(combi_routes, options)
      tags                 = tags_from(paths, options)

      output[:tags]        = tags unless tags.empty? || paths.blank?
      output[:paths]       = paths unless paths.blank?
      output[:definitions] = definitions unless definitions.blank?

      output
    end

    def self.tags_from(paths, options)
      tags = GrapeSwagger::DocMethods::TagNameDescription.build(paths)

      if options[:tags]
        names = options[:tags].map { |t| t[:name] }
        tags.reject! { |t| names.include?(t[:name]) }
        tags += options[:tags]
      end

      tags
    end

    def hide_documentation_path
      @@hide_documentation_path
    end

    def mount_path
      @@mount_path
    end

    def setup(options)
      options = DEFAULTS.merge(options)

      # options could be set on #add_swagger_documentation call,
      # for available options see #defaults
      target_class     = options[:target_class]
      guard            = options[:swagger_endpoint_guard]
      api_doc          = options[:api_documentation].dup
      specific_api_doc = options[:specific_api_documentation].dup

      class_variables_from(options)

      setup_formatter(options[:format])

      desc api_doc.delete(:desc), api_doc

      instance_eval(guard) unless guard.nil?

      get mount_path do
        header['Access-Control-Allow-Origin']   = '*'
        header['Access-Control-Request-Method'] = '*'

        GrapeSwagger::DocMethods
          .output_path_definitions(target_class.combined_namespace_routes, self, target_class, options)
      end

      desc specific_api_doc.delete(:desc), { params: specific_api_doc.delete(:params) || {}, **specific_api_doc }

      params do
        requires :name, type: String, desc: 'Resource name of mounted API'
        optional :locale, type: Symbol, desc: 'Locale of API documentation'
      end

      instance_eval(guard) unless guard.nil?

      get "#{mount_path}/:name" do
        I18n.locale = params[:locale] || I18n.default_locale

        combined_routes = target_class.combined_namespace_routes[params[:name]]
        error!({ error: 'named resource not exist' }, 400) if combined_routes.nil?

        GrapeSwagger::DocMethods
          .output_path_definitions({ params[:name] => combined_routes }, self, target_class, options)
      end
    end

    def class_variables_from(options)
      @@mount_path              = options[:mount_path]
      @@class_name              = options[:class_name] || options[:mount_path].delete('/')
      @@hide_documentation_path = options[:hide_documentation_path]
    end

    def setup_formatter(formatter)
      return unless formatter

      FORMATTER_METHOD.each { |method| send(method, formatter) }
    end
  end
end
