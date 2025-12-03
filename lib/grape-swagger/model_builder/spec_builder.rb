# frozen_string_literal: true

module GrapeSwagger
  module ModelBuilder
    # Builds ApiModel::Spec from Grape API routes and configuration.
    # This is the main entry point for converting Grape routes to the API model.
    class SpecBuilder
      attr_reader :spec, :definitions

      def initialize(options = {})
        @options = options
        @definitions = {}
        @spec = ApiModel::Spec.new
        @schema_builder = SchemaBuilder.new(@definitions)
        @operation_builder = OperationBuilder.new(@schema_builder, @definitions)
      end

      # Build the complete spec from swagger output hash
      # This allows gradual migration - we can build from existing swagger hash
      def build_from_swagger_hash(swagger_hash)
        build_info(swagger_hash[:info])
        build_host_and_servers(swagger_hash)
        build_content_types(swagger_hash)
        build_paths(swagger_hash[:paths])
        build_definitions(swagger_hash[:definitions])
        build_security(swagger_hash)
        build_tags(swagger_hash[:tags])
        build_extensions(swagger_hash)

        @spec
      end

      private

      def build_info(info_hash)
        return unless info_hash

        @spec.info = ApiModel::Info.new(
          title: info_hash[:title],
          description: info_hash[:description],
          terms_of_service: info_hash[:termsOfService],
          version: info_hash[:version],
          contact_name: info_hash.dig(:contact, :name),
          contact_email: info_hash.dig(:contact, :email),
          contact_url: info_hash.dig(:contact, :url),
          license_name: info_hash.dig(:license, :name),
          license_url: info_hash.dig(:license, :url)
        )

        # Copy extensions
        info_hash.each do |key, value|
          @spec.info.extensions[key] = value if key.to_s.start_with?('x-')
        end
      end

      def build_host_and_servers(swagger_hash)
        @spec.host = swagger_hash[:host]
        @spec.base_path = swagger_hash[:basePath]
        @spec.schemes = Array(swagger_hash[:schemes]) if swagger_hash[:schemes]

        # Build servers for OAS3
        if swagger_hash[:host]
          schemes = swagger_hash[:schemes] || ['https']
          schemes.each do |scheme|
            @spec.add_server(
              ApiModel::Server.from_swagger2(
                host: swagger_hash[:host],
                base_path: swagger_hash[:basePath],
                scheme: scheme
              )
            )
          end
        end
      end

      def build_content_types(swagger_hash)
        @spec.produces = swagger_hash[:produces] if swagger_hash[:produces]
        @spec.consumes = swagger_hash[:consumes] if swagger_hash[:consumes]
      end

      def build_paths(paths_hash)
        return unless paths_hash

        paths_hash.each do |path, methods|
          path_item = ApiModel::PathItem.new(path: path)

          methods.each do |method, operation_hash|
            next unless operation_hash.is_a?(Hash)

            operation = build_operation(method, operation_hash)
            path_item.add_operation(method, operation)
          end

          @spec.add_path(path, path_item)
        end
      end

      def build_operation(method, operation_hash)
        operation = ApiModel::Operation.new

        operation.operation_id = operation_hash[:operationId]
        operation.summary = operation_hash[:summary]
        operation.description = operation_hash[:description]
        operation.deprecated = operation_hash[:deprecated] if operation_hash.key?(:deprecated)
        operation.tags = operation_hash[:tags] if operation_hash[:tags]
        operation.produces = operation_hash[:produces] if operation_hash[:produces]
        operation.consumes = operation_hash[:consumes] if operation_hash[:consumes]
        operation.security = operation_hash[:security] if operation_hash[:security]

        # Build parameters
        if operation_hash[:parameters]
          form_data_params = []
          operation_hash[:parameters].each do |param_hash|
            param = build_parameter(param_hash)
            if param.location == 'body'
              build_request_body_from_param(operation, param, operation_hash[:consumes] || @spec.consumes)
            elsif param.location == 'formData'
              form_data_params << param
            else
              operation.add_parameter(param)
            end
          end

          # Convert formData params to requestBody for OAS3
          if form_data_params.any?
            build_request_body_from_form_data(operation, form_data_params, operation_hash[:consumes] || @spec.consumes)
          end
        end

        # Build responses
        if operation_hash[:responses]
          produces = operation_hash[:produces] || @spec.produces || ['application/json']
          operation_hash[:responses].each do |code, response_hash|
            response = build_response(code, response_hash, produces)
            operation.add_response(code, response)
          end
        end

        # Copy extensions
        operation_hash.each do |key, value|
          operation.extensions[key] = value if key.to_s.start_with?('x-')
        end

        operation
      end

      def build_parameter(param_hash)
        param = ApiModel::Parameter.new

        param.name = param_hash[:name]
        param.location = param_hash[:in]
        param.description = param_hash[:description]
        param.required = param_hash[:required]

        # Inline type properties (Swagger 2.0)
        param.type = param_hash[:type]
        param.format = param_hash[:format]
        param.items = param_hash[:items]
        param.collection_format = param_hash[:collectionFormat]
        param.default = param_hash[:default]
        param.enum = param_hash[:enum]
        param.minimum = param_hash[:minimum]
        param.maximum = param_hash[:maximum]
        param.min_length = param_hash[:minLength]
        param.max_length = param_hash[:maxLength]
        param.pattern = param_hash[:pattern]

        # Build schema for OAS3
        if param_hash[:schema]
          param.schema = @schema_builder.build_from_definition(param_hash[:schema])
        else
          param.schema = @schema_builder.build_from_param(param_hash)
        end

        # Copy extensions
        param_hash.each do |key, value|
          param.extensions[key] = value if key.to_s.start_with?('x-')
        end

        param
      end

      def build_request_body_from_param(operation, body_param, consumes)
        request_body = ApiModel::RequestBody.new
        request_body.required = body_param.required
        request_body.description = body_param.description

        content_types = consumes || ['application/json']
        content_types.each do |content_type|
          schema = body_param.schema || @schema_builder.build_from_param(body_param.to_swagger2_h)
          request_body.add_media_type(content_type, schema: schema)
        end

        operation.request_body = request_body
      end

      def build_request_body_from_form_data(operation, form_data_params, consumes)
        request_body = ApiModel::RequestBody.new

        # Check if any param is required
        request_body.required = form_data_params.any?(&:required)

        # Build schema with all form data params as properties
        schema = ApiModel::Schema.new(type: 'object')
        form_data_params.each do |param|
          prop_schema = param.schema || @schema_builder.build_from_param(param.to_swagger2_h)
          schema.add_property(param.name, prop_schema)
          schema.mark_required(param.name) if param.required
        end

        # Determine content type - use multipart if file present, otherwise form-urlencoded
        has_file = form_data_params.any? { |p| p.schema&.format == 'binary' || p.type == 'file' }
        default_content_type = has_file ? 'multipart/form-data' : 'application/x-www-form-urlencoded'

        content_types = consumes&.any? ? consumes : [default_content_type]
        content_types.each do |content_type|
          request_body.add_media_type(content_type, schema: schema)
        end

        operation.request_body = request_body
      end

      def build_response(code, response_hash, produces)
        response = ApiModel::Response.new
        response.status_code = code.to_s
        response.description = response_hash[:description] || ''

        if response_hash[:schema]
          schema = @schema_builder.build_from_definition(response_hash[:schema])
          response.schema = schema

          # Add media types for OAS3
          if schema.type == 'string' && schema.format == 'binary'
            response.add_media_type('application/octet-stream', schema: schema)
          else
            produces.each do |content_type|
              response.add_media_type(content_type, schema: schema)
            end
          end
        end

        if response_hash[:headers]
          response_hash[:headers].each do |name, header_hash|
            header = ApiModel::Header.new(
              name: name,
              description: header_hash[:description],
              type: header_hash[:type],
              format: header_hash[:format]
            )
            header.schema = @schema_builder.build_from_param(header_hash)
            response.headers[name] = header
          end
        end

        response.examples = response_hash[:examples] if response_hash[:examples]

        # Copy extensions
        response_hash.each do |key, value|
          response.extensions[key] = value if key.to_s.start_with?('x-')
        end

        response
      end

      def build_definitions(definitions_hash)
        return unless definitions_hash

        definitions_hash.each do |name, definition|
          @definitions[name] = definition
          schema = @schema_builder.build_from_definition(definition)
          schema.canonical_name = name
          @spec.components.add_schema(name, schema)
        end
      end

      def build_security(swagger_hash)
        if swagger_hash[:securityDefinitions]
          swagger_hash[:securityDefinitions].each do |name, definition|
            scheme = build_security_scheme(definition)
            @spec.components.add_security_scheme(name, scheme)
          end
        end

        @spec.security = swagger_hash[:security] if swagger_hash[:security]
      end

      def build_security_scheme(definition)
        scheme = ApiModel::SecurityScheme.new

        scheme.type = convert_security_type(definition[:type])
        scheme.description = definition[:description]
        scheme.name = definition[:name]
        scheme.location = definition[:in]

        case definition[:type]
        when 'basic'
          scheme.type = 'http'
          scheme.scheme = 'basic'
        when 'oauth2'
          scheme.flows = build_oauth_flows(definition)
        end

        scheme
      end

      def convert_security_type(type)
        case type
        when 'basic' then 'http'
        when 'apiKey' then 'apiKey'
        when 'oauth2' then 'oauth2'
        else type
        end
      end

      def build_oauth_flows(definition)
        flow_type = case definition[:flow]
                    when 'implicit' then 'implicit'
                    when 'password' then 'password'
                    when 'application' then 'clientCredentials'
                    when 'accessCode' then 'authorizationCode'
                    else definition[:flow]
                    end

        {
          flow_type => {
            authorizationUrl: definition[:authorizationUrl],
            tokenUrl: definition[:tokenUrl],
            scopes: definition[:scopes]
          }.compact
        }
      end

      def build_tags(tags_array)
        return unless tags_array

        tags_array.each do |tag_hash|
          tag = ApiModel::Tag.new(
            name: tag_hash[:name],
            description: tag_hash[:description]
          )
          @spec.add_tag(tag)
        end
      end

      def build_extensions(swagger_hash)
        swagger_hash.each do |key, value|
          @spec.extensions[key] = value if key.to_s.start_with?('x-')
        end
      end
    end
  end
end
