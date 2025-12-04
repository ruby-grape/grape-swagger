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
        token_owner: nil,
        # OpenAPI version: nil (Swagger 2.0), '3.0', or '3.1'
        openapi_version: nil,
        # OpenAPI 3.1 specific options
        json_schema_dialect: nil,
        webhooks: nil
      }.freeze

    FORMATTER_METHOD = %i[format default_format default_error_formatter].freeze

    def self.output_path_definitions(combi_routes, endpoint, target_class, options)
      if options[:openapi_version]
        # Build OpenAPI 3.x directly from Grape routes (no information loss)
        build_openapi3_directly(combi_routes, endpoint, target_class, options)
      else
        # Generate Swagger 2.0 output (original flow)
        build_swagger2_output(combi_routes, endpoint, target_class, options)
      end
    end

    def self.build_swagger2_output(combi_routes, endpoint, target_class, options)
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

    def self.build_openapi3_directly(combi_routes, endpoint, target_class, options)
      version = options[:openapi_version]

      # Build API model directly from Grape routes (preserves all options)
      builder = GrapeSwagger::ModelBuilder::DirectSpecBuilder.new(
        endpoint, target_class, endpoint.request, options
      )
      spec = builder.build(combi_routes)

      # Apply OAS 3.1 specific options
      if version.to_s.start_with?('3.1')
        spec.json_schema_dialect = options[:json_schema_dialect] if options[:json_schema_dialect]
        apply_webhooks(spec, options[:webhooks]) if options[:webhooks]
      end

      # Export to requested OpenAPI version
      GrapeSwagger::Exporter.export(spec, version: version)
    end

    def self.convert_to_openapi3(swagger_output, options)
      version = options[:openapi_version]

      # Build API model from Swagger output
      spec_builder = GrapeSwagger::ModelBuilder::SpecBuilder.new
      spec = spec_builder.build_from_swagger_hash(swagger_output)

      # Apply OAS 3.1 specific options
      if version.to_s.start_with?('3.1')
        spec.json_schema_dialect = options[:json_schema_dialect] if options[:json_schema_dialect]
        apply_webhooks(spec, options[:webhooks]) if options[:webhooks]
      end

      # Export to requested OpenAPI version
      GrapeSwagger::Exporter.export(spec, version: version)
    end

    def self.apply_webhooks(spec, webhooks_config)
      return unless webhooks_config.is_a?(Hash)

      webhooks_config.each do |name, webhook_def|
        path_item = build_webhook_path_item(webhook_def)
        spec.add_webhook(name.to_s, path_item)
      end
    end

    def self.build_webhook_path_item(webhook_def)
      path_item = GrapeSwagger::ApiModel::PathItem.new

      webhook_def.each do |method, operation_def|
        next unless %i[get post put patch delete].include?(method.to_sym)

        operation = GrapeSwagger::ApiModel::Operation.new
        operation.summary = operation_def[:summary]
        operation.description = operation_def[:description]
        operation.operation_id = operation_def[:operationId] || operation_def[:operation_id]
        operation.tags = operation_def[:tags]

        # Build request body if present
        if operation_def[:requestBody]
          request_body = build_webhook_request_body(operation_def[:requestBody])
          operation.request_body = request_body
        end

        # Build responses
        operation_def[:responses]&.each do |code, response_def|
          response = GrapeSwagger::ApiModel::Response.new
          response.description = response_def[:description] || ''
          operation.add_response(code.to_s, response)
        end

        path_item.add_operation(method.to_sym, operation)
      end

      path_item
    end

    def self.build_webhook_request_body(request_body_def)
      request_body = GrapeSwagger::ApiModel::RequestBody.new
      request_body.description = request_body_def[:description]
      request_body.required = request_body_def[:required]

      request_body_def[:content]&.each do |content_type, content_def|
        schema = build_webhook_schema(content_def[:schema]) if content_def[:schema]
        request_body.add_media_type(content_type.to_s, schema: schema)
      end

      request_body
    end

    def self.build_webhook_schema(schema_def)
      return nil unless schema_def

      if schema_def[:$ref] || schema_def['$ref']
        ref = schema_def[:$ref] || schema_def['$ref']
        schema = GrapeSwagger::ApiModel::Schema.new
        schema.canonical_name = ref.split('/').last
        return schema
      end

      schema = GrapeSwagger::ApiModel::Schema.new
      schema.type = schema_def[:type]
      schema.format = schema_def[:format]
      schema.description = schema_def[:description]

      schema_def[:properties]&.each do |prop_name, prop_def|
        prop_schema = build_webhook_schema(prop_def)
        schema.add_property(prop_name.to_s, prop_schema)
      end

      schema.required = Array(schema_def[:required]) if schema_def[:required]

      schema
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
