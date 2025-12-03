# frozen_string_literal: true

module GrapeSwagger
  module ModelBuilder
    # Builds ApiModel::Operation objects from Grape route definitions.
    class OperationBuilder
      def initialize(schema_builder, definitions = {})
        @schema_builder = schema_builder
        @parameter_builder = ParameterBuilder.new(schema_builder)
        @response_builder = ResponseBuilder.new(schema_builder, definitions)
        @definitions = definitions
      end

      # Build an operation from route and parsed parameters/responses
      # rubocop:disable Lint/UnusedMethodArgument
      def build(method:, params:, responses:, route_options:, content_types: {})
        # rubocop:enable Lint/UnusedMethodArgument
        operation = ApiModel::Operation.new

        # Basic info
        operation.operation_id = route_options[:operation_id]
        operation.summary = route_options[:summary]
        operation.description = route_options[:description]
        operation.deprecated = route_options[:deprecated] if route_options.key?(:deprecated)
        operation.tags = Array(route_options[:tags]) if route_options[:tags]

        # Content types (Swagger 2.0 style)
        operation.produces = content_types[:produces] if content_types[:produces]
        operation.consumes = content_types[:consumes] if content_types[:consumes]

        # Security
        operation.security = route_options[:security] if route_options[:security]

        # Build parameters
        build_parameters(operation, params, content_types[:consumes])

        # Build responses
        build_responses(operation, responses, content_types[:produces])

        # Copy extension fields
        route_options.each do |key, value|
          operation.extensions[key] = value if key.to_s.start_with?('x-')
        end

        operation
      end

      private

      def build_parameters(operation, params, consumes)
        return unless params&.any?

        params.each do |param_hash|
          param = @parameter_builder.build(param_hash)

          if param.location == 'body'
            # Body params become request body in OAS3
            build_request_body(operation, param, consumes)
          elsif param.location == 'formData'
            # Form data also becomes request body in OAS3
            add_form_param_to_request_body(operation, param, consumes)
          else
            operation.add_parameter(param)
          end
        end
      end

      def build_request_body(operation, body_param, consumes)
        request_body = operation.request_body || ApiModel::RequestBody.new
        request_body.required = body_param.required
        request_body.description = body_param.description

        content_types = consumes || ['application/json']
        content_types.each do |content_type|
          request_body.add_media_type(content_type, schema: body_param.schema)
        end

        operation.request_body = request_body
      end

      def add_form_param_to_request_body(operation, form_param, _consumes)
        request_body = operation.request_body || ApiModel::RequestBody.new

        # Determine content type for form data
        has_file = form_param.type == 'file' ||
                   (form_param.schema && form_param.schema.type == 'string' && form_param.schema.format == 'binary')
        content_type = has_file ? 'multipart/form-data' : 'application/x-www-form-urlencoded'

        # Get or create the form schema
        form_media_type = request_body.media_types.find { |mt| mt.mime_type == content_type }

        if form_media_type
          # Add property to existing schema
          form_schema = form_media_type.schema
        else
          form_schema = ApiModel::Schema.new(type: 'object')
          request_body.add_media_type(content_type, schema: form_schema)
        end

        # Add the parameter as a property
        prop_schema = form_param.schema || @schema_builder.build_from_param(
          type: form_param.type,
          format: form_param.format
        )

        # Convert file type for OAS3
        prop_schema = ApiModel::Schema.new(type: 'string', format: 'binary') if form_param.type == 'file'

        form_schema.add_property(form_param.name, prop_schema)
        form_schema.mark_required(form_param.name) if form_param.required

        operation.request_body = request_body
      end

      def build_responses(operation, responses, produces)
        return unless responses

        content_types = produces || ['application/json']

        responses.each do |code, response_hash|
          response = @response_builder.build(code, response_hash, content_types: content_types)
          operation.add_response(code, response)
        end
      end
    end
  end
end
