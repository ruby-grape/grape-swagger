# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Builder
    # Builds OpenAPI::Document directly from Grape routes without intermediate Swagger 2.0 hash.
    # This preserves all Grape options that would otherwise be lost in conversion (e.g., allow_blank → nullable).
    #
    # Architecture:
    #   Grape Routes → FromRoutes → OpenAPI Model → Exporter → OAS3 Output
    #
    # This is the active path for OAS3 generation. The Swagger 2.0 path remains unchanged:
    #   Grape Routes → endpoint.rb → Swagger Hash
    class FromRoutes
      attr_reader :spec, :definitions, :options

      def initialize(endpoint, target_class, request, options)
        @endpoint = endpoint
        @target_class = target_class
        @request = request
        @options = options
        @definitions = {}
        @spec = OpenAPI::Document.new
        @schema_builder = SchemaBuilder.new(@definitions)
      end

      def build(namespace_routes)
        # Initialize @definitions on endpoint so model parsers can use it
        @endpoint.instance_variable_set(:@definitions, @definitions)

        build_info
        build_servers
        build_content_types
        build_security_definitions
        build_paths(namespace_routes)
        build_tags
        build_extensions

        @spec
      end

      private

      # ==================== Info ====================

      def build_info
        info_options = options[:info] || {}
        @spec.info = OpenAPI::Info.new(
          title: info_options[:title] || 'API title',
          description: info_options[:description],
          terms_of_service: info_options[:terms_of_service_url],
          version: options[:doc_version] || info_options[:version] || '1.0',
          contact_name: info_options[:contact_name],
          contact_email: info_options[:contact_email],
          contact_url: info_options[:contact_url]
        )

        build_license(info_options)
        copy_info_extensions(info_options)
      end

      def build_license(info_options)
        license = info_options[:license]
        return unless license

        if license.is_a?(Hash)
          @spec.info.license_name = license[:name]
          @spec.info.license_url = license[:url] || info_options[:license_url]
          @spec.info.license_identifier = license[:identifier]
        else
          @spec.info.license_name = license
          @spec.info.license_url = info_options[:license_url]
        end
      end

      def copy_info_extensions(info_options)
        info_options.each do |key, value|
          @spec.info.extensions[key] = value if key.to_s.start_with?('x-')
        end
      end

      # ==================== Servers ====================

      def build_servers
        host = GrapeSwagger::DocMethods::OptionalObject.build(:host, options, @request)
        base_path = GrapeSwagger::DocMethods::OptionalObject.build(:base_path, options, @request)
        schemes = normalize_schemes(options[:schemes])

        # Store for Swagger 2.0 compatibility
        @spec.host = host
        @spec.base_path = base_path
        @spec.schemes = schemes

        # Build OAS3 servers
        return unless host

        (schemes.presence || ['https']).each do |scheme|
          @spec.add_server(
            OpenAPI::Server.from_swagger2(host: host, base_path: base_path, scheme: scheme)
          )
        end
      end

      def normalize_schemes(schemes)
        return [] unless schemes

        schemes.is_a?(String) ? [schemes] : Array(schemes)
      end

      # ==================== Content Types ====================

      def build_content_types
        @spec.produces = options[:produces] || content_types_for_target
        @spec.consumes = options[:consumes]
      end

      def content_types_for_target
        @endpoint.content_types_for(@target_class)
      end

      # ==================== Security ====================

      def build_security_definitions
        return unless options[:security_definitions]

        options[:security_definitions].each do |name, definition|
          scheme = build_security_scheme(definition)
          @spec.components.add_security_scheme(name, scheme)
        end

        @spec.security = options[:security] if options[:security]
      end

      def build_security_scheme(definition)
        scheme = OpenAPI::SecurityScheme.new
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

      # ==================== Paths ====================

      def build_paths(namespace_routes)
        # Add models from options
        add_definitions_from(options[:models])

        namespace_routes.each_value do |routes|
          routes.each do |route|
            next if hidden?(route)

            build_path_item(route)
          end
        end
      end

      def add_definitions_from(models)
        return unless models

        models.each { |model| expose_params_from_model(model) }
      end

      def build_path_item(route)
        @current_item, path = GrapeSwagger::DocMethods::PathString.build(route, options)
        @current_entity = route.entity || route.options[:success]

        path_item = @spec.paths[path] || OpenAPI::PathItem.new(path: path)
        operation = build_operation(route, path)
        path_item.add_operation(route.request_method.downcase.to_sym, operation)

        @spec.add_path(path, path_item)

        # Handle path-level extensions
        add_path_extensions(path_item, route)
      end

      def add_path_extensions(path_item, route)
        x_path = route.settings.dig(:x_path)
        return unless x_path

        x_path.each do |key, value|
          path_item.extensions["x-#{key}"] = value
        end
      end

      # ==================== Operations ====================

      def build_operation(route, path)
        operation = OpenAPI::Operation.new
        operation.operation_id = GrapeSwagger::DocMethods::OperationId.build(route, path)
        operation.summary = build_summary(route)
        operation.description = build_description(route)
        operation.deprecated = route.options[:deprecated] if route.options.key?(:deprecated)
        operation.tags = route.options.fetch(:tags, build_tags_for_route(route, path))
        operation.security = route.options[:security] if route.options.key?(:security)
        operation.produces = build_produces(route)
        operation.consumes = build_consumes(route)

        build_operation_parameters(operation, route, path)
        build_operation_responses(operation, route)
        add_operation_extensions(operation, route)

        operation
      end

      def build_summary(route)
        summary = route.options[:desc] if route.options.key?(:desc)
        summary = route.description if route.description.present? && route.options.key?(:detail)
        summary = route.options[:summary] if route.options.key?(:summary)
        summary
      end

      def build_description(route)
        description = route.description if route.description.present?
        description = route.options[:detail] if route.options.key?(:detail)
        description
      end

      def build_produces(route)
        return ['application/octet-stream'] if file_response?(route.attributes.success) &&
                                               !route.attributes.produces.present?

        format = options[:produces] || options[:format]
        mime_types = GrapeSwagger::DocMethods::ProducesConsumes.call(format)

        route_mime_types = %i[formats content_types produces].filter_map do |producer|
          possible = route.options[producer]
          GrapeSwagger::DocMethods::ProducesConsumes.call(possible) if possible.present?
        end.flatten.uniq

        route_mime_types.presence || mime_types
      end

      def build_consumes(route)
        return unless %i[post put patch].include?(route.request_method.downcase.to_sym)

        format = options[:consumes] || options[:format]
        GrapeSwagger::DocMethods::ProducesConsumes.call(
          route.settings.dig(:description, :consumes) || format
        )
      end

      def build_tags_for_route(route, path)
        version = GrapeSwagger::DocMethods::Version.get(route)
        version = Array(version)
        prefix = route.prefix.to_s.split('/').reject(&:empty?)

        Array(
          path.split('{')[0].split('/').reject(&:empty?).delete_if do |i|
            prefix.include?(i) || version.map(&:to_s).include?(i)
          end.first
        ).presence
      end

      def add_operation_extensions(operation, route)
        x_operation = route.settings.dig(:x_operation)
        return unless x_operation

        x_operation.each do |key, value|
          operation.extensions["x-#{key}"] = value
        end
      end

      # ==================== Parameters ====================

      def build_operation_parameters(operation, route, path)
        raw_params = build_request_params(route)
        consumes = operation.consumes || @spec.consumes

        # Separate by location
        body_params = []
        form_data_params = []

        raw_params.each do |name, param_options|
          next if hidden_parameter?(param_options)

          param = build_parameter(name, param_options, route, path, consumes)

          # Nested params (with [ in name) are always treated as body params
          # regardless of their declared location, following move_params behavior
          is_nested = name.to_s.include?('[')

          case param.location
          when 'body'
            body_params << { name: name, options: param_options, param: param }
          when 'formData'
            if is_nested
              # Nested formData params are part of the body schema
              body_params << { name: name, options: param_options, param: param }
            else
              form_data_params << param
            end
          else
            operation.add_parameter(param)
          end
        end

        # Build request body from body params
        if body_params.any?
          build_request_body_from_params(operation, body_params, consumes, route, path)
        elsif form_data_params.any?
          build_request_body_from_form_data(operation, form_data_params, consumes)
        end
      end

      def build_request_params(route)
        GrapeSwagger.request_param_parsers.each_with_object({}) do |parser_klass, accum|
          params = parser_klass.parse(route, accum, options, @endpoint)
          accum.merge!(params.stringify_keys)
        end
      end

      def build_parameter(name, param_options, route, path, consumes)
        param = OpenAPI::Parameter.new
        param.name = param_options[:full_name] || name

        # Determine location
        param.location = determine_param_location(name, param_options, route, path, consumes)

        # Description
        param.description = param_options[:desc] || param_options[:description]

        # Required
        param.required = param.location == 'path' || param_options[:required] || false

        # Build schema with ALL Grape options preserved
        param.schema = build_param_schema(param_options)

        # Deprecated
        param.deprecated = param_options[:deprecated] if param_options.key?(:deprecated)

        # Copy extensions
        copy_param_extensions(param, param_options)

        param
      end

      def determine_param_location(name, param_options, route, path, consumes)
        # Check if in path
        return 'path' if path.include?("{#{name}}")

        # Check documentation options
        doc = param_options[:documentation] || {}
        return doc[:param_type] if doc[:param_type]
        return doc[:in] if doc[:in]

        # Default based on HTTP method
        if %w[POST PUT PATCH].include?(route.request_method)
          if consumes&.any? { |c| c.include?('form') }
            'formData'
          else
            'body'
          end
        else
          'query'
        end
      end

      def build_param_schema(param_options)
        schema = OpenAPI::Schema.new

        # Get type info
        data_type = GrapeSwagger::DocMethods::DataType.call(param_options)
        apply_type_to_schema(schema, data_type, param_options)

        # CRITICAL: Preserve nullable from Grape options
        # This is where we gain information that was lost before!
        schema.nullable = true if param_options[:allow_blank]

        doc = param_options[:documentation] || {}
        schema.nullable = true if doc[:nullable]

        # Handle additional_properties from documentation
        # For arrays, apply to items schema; for objects, apply to schema itself
        if doc.key?(:additional_properties)
          if schema.type == 'array' && schema.items
            apply_additional_properties(schema.items, doc[:additional_properties])
          else
            apply_additional_properties(schema, doc[:additional_properties])
          end
        end

        # Other constraints
        apply_constraints_to_schema(schema, param_options)

        schema
      end

      def apply_additional_properties(schema, additional_props)
        case additional_props
        when true, false
          schema.additional_properties = additional_props
        when String
          # Type as string
          schema.additional_properties = { type: additional_props.downcase }
        when Class
          # Entity class - need to expose and create ref
          is_entity = begin
            additional_props < Grape::Entity
          rescue StandardError
            false
          end
          if is_entity
            model_name = expose_params_from_model(additional_props)
            schema.additional_properties = { canonical_name: model_name } if model_name
          else
            type_name = GrapeSwagger::DocMethods::DataType.call(type: additional_props)
            schema.additional_properties = { type: type_name }
          end
        when Hash
          schema.additional_properties = additional_props
        end
      end

      def apply_type_to_schema(schema, data_type, param_options)
        # Check for Array[Entity] type first (e.g., Array[Entities::ApiError])
        original_type = param_options[:type]

        # Handle both Ruby Array class with element AND string representation "[Entity]"
        element_class = extract_array_element_class(original_type)
        if element_class
          # Check if there's a model parser that can handle this class
          has_parser = GrapeSwagger.model_parsers.find(element_class) rescue false

          schema.type = 'array'
          if has_parser
            # Expose the entity and create a ref
            model_name = expose_params_from_model(element_class)
            items = OpenAPI::Schema.new
            items.canonical_name = model_name if model_name
            schema.items = items
          else
            schema.items = build_array_items_schema(param_options, data_type)
          end
        # Check for array (is_array flag or 'array' type)
        elsif data_type == 'array' || param_options[:is_array]
          schema.type = 'array'
          schema.items = build_array_items_schema(param_options, data_type)
        elsif GrapeSwagger::DocMethods::DataType.primitive?(data_type)
          type, format = GrapeSwagger::DocMethods::DataType.mapping(data_type)
          schema.type = type
          schema.format = param_options[:format] || format
        elsif data_type == 'file'
          # OAS3: file type becomes string with binary format
          schema.type = 'string'
          schema.format = 'binary'
        elsif data_type == 'json' || data_type == 'JSON'
          # JSON type maps to object in OAS3
          schema.type = 'object'
        elsif @definitions.key?(data_type)
          schema.canonical_name = data_type
        else
          handled = false

          # Check if original_type is a Class with a model parser
          # This handles cases like `type: Entities::ApiResponse`
          if original_type.is_a?(Class)
            has_parser = GrapeSwagger.model_parsers.find(original_type) rescue false
            if has_parser
              model_name = expose_params_from_model(original_type)
              schema.canonical_name = model_name if model_name
              handled = true
            end
          end

          # Check if original_type is a string representation of a Class
          if !handled && original_type.is_a?(String) && !GrapeSwagger::DocMethods::DataType.primitive?(original_type)
            begin
              klass = Object.const_get(original_type)
              has_parser = GrapeSwagger.model_parsers.find(klass) rescue false
              if has_parser
                model_name = expose_params_from_model(klass)
                schema.canonical_name = model_name if model_name
                handled = true
              end
            rescue NameError
              # Not a valid class name
            end
          end

          schema.type = data_type unless handled
        end
      end

      # Extract the element class from Array types
      # Handles both Ruby Array[Class] and string "[ClassName]"
      def extract_array_element_class(type)
        # Handle Ruby Array with element class (e.g., Array[Entities::ApiError])
        if type.is_a?(Array) && type.first.is_a?(Class)
          return type.first
        end

        # Handle string representation (e.g., "[Entities::ApiError]")
        if type.is_a?(String) && type =~ /\A\[(.+)\]\z/
          class_name = ::Regexp.last_match(1).strip
          # Try to resolve to an actual class
          begin
            return Object.const_get(class_name)
          rescue NameError
            # Class not found, return nil
            return nil
          end
        end

        nil
      end

      def build_array_items_schema(param_options, data_type = nil)
        items = OpenAPI::Schema.new
        doc = param_options[:documentation] || {}

        # Determine item type from documentation, data_type, or default to string
        item_type = if doc[:type]
                      GrapeSwagger::DocMethods::DataType.call(type: doc[:type])
                    elsif data_type && data_type != 'array'
                      data_type
                    else
                      'string'
                    end

        if GrapeSwagger::DocMethods::DataType.primitive?(item_type)
          type, format = GrapeSwagger::DocMethods::DataType.mapping(item_type)
          items.type = type
          items.format = format
        elsif item_type == 'file'
          # OAS3: file type becomes string with binary format
          items.type = 'string'
          items.format = 'binary'
        elsif @definitions.key?(item_type)
          items.canonical_name = item_type
        else
          items.type = item_type
        end

        items
      end

      def apply_constraints_to_schema(schema, param_options)
        # Values (enum or range)
        values = param_options[:values]
        case values
        when Range
          schema.minimum = values.begin if values.begin.is_a?(Integer)
          schema.maximum = values.end if values.end.is_a?(Integer)
        when Array
          schema.enum = values
        when Proc
          result = values.call if values.parameters.empty?
          schema.enum = result if result.is_a?(Array)
        end

        # Default
        schema.default = param_options[:default] if param_options.key?(:default)

        # Length constraints
        schema.min_length = param_options[:min_length] if param_options[:min_length]
        schema.max_length = param_options[:max_length] if param_options[:max_length]

        # Description - check multiple locations
        doc = param_options[:documentation] || {}
        schema.description = param_options[:desc] ||
                             param_options[:description] ||
                             doc[:desc] ||
                             doc[:description]
      end

      def copy_param_extensions(param, param_options)
        doc = param_options[:documentation] || {}

        # x- extensions from documentation
        doc.fetch(:x, {}).each do |key, value|
          param.extensions["x-#{key}"] = value
        end

        # Direct x- keys
        param_options.each do |key, value|
          param.extensions[key.to_s] = value if key.to_s.start_with?('x-')
        end
      end

      # ==================== Request Body ====================

      def build_request_body_from_params(operation, body_params, consumes, route, path)
        request_body = OpenAPI::RequestBody.new
        request_body.required = body_params.any? { |bp| bp[:options][:required] }
        request_body.description = route.description

        # Build schema with nested structure support
        schema = build_nested_body_schema(body_params, route)

        # Store definition and create reference schema
        definition_name = GrapeSwagger::DocMethods::OperationId.build(route, path)
        @definitions[definition_name] = { type: 'object' } # Placeholder
        @spec.components.add_schema(definition_name, schema)

        # Create a reference schema for the requestBody
        ref_schema = OpenAPI::Schema.new
        ref_schema.canonical_name = definition_name

        content_types = consumes || ['application/json']
        content_types.each do |content_type|
          request_body.add_media_type(content_type, schema: ref_schema)
        end

        operation.request_body = request_body
      end

      def build_nested_body_schema(body_params, route)
        schema = OpenAPI::Schema.new(type: 'object')
        schema.description = route.description

        # Separate top-level params from nested params
        top_level = []
        nested = []
        body_params.each do |bp|
          if bp[:name].to_s.include?('[')
            nested << bp
          else
            top_level << bp
          end
        end

        # Process each top-level param
        top_level.each do |bp|
          name = bp[:name].to_s
          prop_schema = build_param_schema(bp[:options])

          # Find nested params that belong to this top-level param
          related_nested = nested.select { |n| n[:name].to_s.start_with?("#{name}[") }

          if related_nested.any?
            # Build nested structure into prop_schema
            build_nested_properties(prop_schema, name, related_nested)
          end

          schema.add_property(name, prop_schema)
          schema.mark_required(name) if bp[:options][:required]
        end

        schema
      end

      def build_nested_properties(parent_schema, parent_name, nested_params)
        # Group nested params by their immediate child
        children = {}
        nested_params.each do |np|
          # Remove parent prefix: "contact[name]" -> "name]", "contact[addresses][street]" -> "addresses][street]"
          remainder = np[:name].to_s.sub("#{parent_name}[", '')
          # Get the immediate child name
          if remainder.include?('][')
            child_name = remainder.split('][').first.chomp(']')
          else
            child_name = remainder.chomp(']')
          end
          children[child_name] ||= []
          children[child_name] << np
        end

        # Build each child
        children.each do |child_name, child_params|
          # Find the direct child param (exact match)
          direct_param = child_params.find { |p| p[:name].to_s == "#{parent_name}[#{child_name}]" }

          if direct_param
            child_schema = build_param_schema(direct_param[:options])

            # Find deeper nested params
            deeper_nested = child_params.reject { |p| p[:name].to_s == "#{parent_name}[#{child_name}]" }

            if deeper_nested.any?
              if child_schema.type == 'array' && child_schema.items
                # For arrays, build into items
                build_nested_properties(child_schema.items, "#{parent_name}[#{child_name}]", deeper_nested)
              else
                # For objects, build into the schema itself
                build_nested_properties(child_schema, "#{parent_name}[#{child_name}]", deeper_nested)
              end
            end

            # Add to parent (handle both array items and object properties)
            if parent_schema.type == 'array' && parent_schema.items
              # If we're adding properties to array items, ensure it's type: object
              # (override default 'string' type since we're adding nested properties)
              parent_schema.items.type = 'object'
              parent_schema.items.format = nil  # Clear any format from the string type
              parent_schema.items.add_property(child_name, child_schema)
              parent_schema.items.mark_required(child_name) if direct_param[:options][:required]
            else
              # If parent is a primitive type (e.g., array items defaulting to string),
              # convert it to object since we're adding properties
              if parent_schema.type && parent_schema.type != 'object' && parent_schema.type != 'array'
                parent_schema.type = 'object'
                parent_schema.format = nil
              end
              parent_schema.add_property(child_name, child_schema)
              parent_schema.mark_required(child_name) if direct_param[:options][:required]
            end
          end
        end
      end

      def build_request_body_from_form_data(operation, form_data_params, consumes)
        request_body = OpenAPI::RequestBody.new
        request_body.required = form_data_params.any?(&:required)

        schema = OpenAPI::Schema.new(type: 'object')
        form_data_params.each do |param|
          schema.add_property(param.name, param.schema)
          schema.mark_required(param.name) if param.required
        end

        has_file = form_data_params.any? { |p| p.schema&.format == 'binary' }
        default_content_type = has_file ? 'multipart/form-data' : 'application/x-www-form-urlencoded'

        content_types = consumes&.any? ? consumes : [default_content_type]
        content_types.each do |content_type|
          request_body.add_media_type(content_type, schema: schema)
        end

        operation.request_body = request_body
      end

      # ==================== Responses ====================

      def build_operation_responses(operation, route)
        codes = build_response_codes(route)

        codes.each do |code_info|
          response = build_response(code_info, route)
          operation.add_response(code_info[:code], response)
        end
      end

      def build_response_codes(route)
        if route.http_codes.is_a?(Array) && route.http_codes.any? { |c| success_code?(c) }
          route.http_codes.map { |c| normalize_code(c) }
        else
          success_codes = build_success_codes(route)
          default_codes = build_default_codes(route)
          failure_codes = (route.http_codes || route.options[:failure] || []).map { |c| normalize_code(c) }
          success_codes + default_codes + failure_codes
        end
      end

      def build_default_codes(route)
        entity = route.options[:default_response]
        return [] if entity.nil?

        default_code = { code: 'default', message: 'Default Response' }
        if entity.is_a?(Hash)
          default_code[:message] = entity[:message] || default_code[:message]
          default_code[:model] = entity[:model] if entity[:model]
        else
          default_code[:model] = entity
        end

        [default_code]
      end

      def success_code?(code)
        status = code.is_a?(Array) ? code.first : code[:code]
        status.between?(200, 299)
      end

      def normalize_code(code)
        if code.is_a?(Array)
          { code: code[0], message: code[1], model: code[2], examples: code[3], headers: code[4] }
        else
          code
        end
      end

      def build_success_codes(route)
        entity = @current_entity

        # Handle Array of success codes
        if entity.is_a?(Array)
          return entity.map { |e| success_code_from_entity(route, e) }
        end

        [success_code_from_entity(route, entity)]
      end

      def success_code_from_entity(route, entity)
        default_code = GrapeSwagger::DocMethods::StatusCodes.get[route.request_method.downcase.to_sym].dup

        if entity.is_a?(Hash)
          default_code[:code] = entity[:code] if entity[:code]
          default_code[:model] = entity[:model] if entity[:model]
          default_code[:headers] = entity[:headers] if entity[:headers]
          default_code[:is_array] = entity[:is_array] if entity[:is_array]
          default_code[:message] = entity[:message] || route.description || default_code[:message].sub('{item}', @current_item)
        elsif entity
          default_code[:model] = entity
          default_code[:message] = route.description || default_code[:message].sub('{item}', @current_item)
        else
          default_code[:message] = route.description || default_code[:message].sub('{item}', @current_item)
        end

        # DELETE without model should use 204 instead of 200
        if route.request_method == 'DELETE' && default_code[:model].nil? && default_code[:code] == 200
          default_code[:code] = 204
        end

        default_code
      end

      def build_response(code_info, route)
        response = OpenAPI::Response.new
        response.status_code = code_info[:code].to_s
        response.description = code_info[:message] || ''

        # Handle file response
        if file_response?(code_info[:model])
          schema = OpenAPI::Schema.new(type: 'string', format: 'binary')
          response.add_media_type('application/octet-stream', schema: schema)
          return response
        end

        # Explicitly request no model with { model: '' }
        unless code_info[:model] == ''
          # Handle model response - explicit or implicit
          model_name = if code_info[:model]
                         expose_params_from_model(code_info[:model])
                       else
                         # Implicit model: use @current_item if it exists in @definitions
                         @current_item if @definitions[@current_item]
                       end

          if model_name && @definitions[model_name]
            schema = OpenAPI::Schema.new
            schema.canonical_name = model_name

            # Handle array responses
            if route.options[:is_array] || code_info[:is_array]
              array_schema = OpenAPI::Schema.new(type: 'array', items: schema)
              schema = array_schema
            end

            produces = build_produces(route)
            produces.each do |content_type|
              response.add_media_type(content_type, schema: schema)
            end
          end
        end

        # Headers
        code_info[:headers]&.each do |name, header_info|
          header = OpenAPI::Header.new(
            name: name,
            description: header_info[:description],
            type: header_info[:type],
            format: header_info[:format]
          )
          response.headers[name] = header
        end

        response
      end

      # ==================== Tags ====================

      def build_tags
        # Collect unique tags from all operations
        all_tags = Set.new
        @spec.paths.each_value do |path_item|
          path_item.operations.each do |_method, operation|
            next unless operation&.tags

            operation.tags.each { |tag| all_tags << tag }
          end
        end

        # Build tag objects with descriptions
        all_tags.each do |tag_name|
          tag = OpenAPI::Tag.new(
            name: tag_name,
            description: "Operations about #{tag_name.to_s.pluralize}"
          )
          @spec.add_tag(tag)
        end

        # Merge with user-provided tags
        if options[:tags]
          user_tag_names = options[:tags].map { |t| t[:name] }
          @spec.tags.reject! { |t| user_tag_names.include?(t.name) }

          options[:tags].each do |tag_hash|
            tag = OpenAPI::Tag.new(
              name: tag_hash[:name],
              description: tag_hash[:description]
            )
            @spec.add_tag(tag)
          end
        end
      end

      # ==================== Extensions ====================

      def build_extensions
        GrapeSwagger::DocMethods::Extensions.add_extensions_to_root(options, @spec.extensions)
      end

      # ==================== Helpers ====================

      def hidden?(route)
        route_hidden = route.settings.try(:[], :swagger).try(:[], :hidden)
        route_hidden = route.options[:hidden] if route.options.key?(:hidden)
        return route_hidden unless route_hidden.is_a?(Proc)

        return route_hidden.call unless options[:token_owner]

        token_owner = GrapeSwagger::TokenOwnerResolver.resolve(@endpoint, options[:token_owner])
        GrapeSwagger::TokenOwnerResolver.evaluate_proc(route_hidden, token_owner)
      end

      def hidden_parameter?(param_options)
        return false if param_options[:required]

        doc = param_options[:documentation] || {}
        hidden = doc[:hidden]

        if hidden.is_a?(Proc)
          hidden.call
        else
          hidden
        end
      end

      def file_response?(value)
        value.to_s.casecmp('file').zero?
      end

      def expose_params_from_model(model)
        # Handle array format (from failure codes) or empty/nil values
        return nil if model.nil? || model.is_a?(Array)
        return nil if model.is_a?(String) && model.strip.empty?

        model = model.constantize if model.is_a?(String)
        model_name = GrapeSwagger::DocMethods::DataType.parse_entity_name(model)

        return model_name if @definitions.key?(model_name)

        @definitions[model_name] = nil

        parser = GrapeSwagger.model_parsers.find(model)
        raise GrapeSwagger::Errors::UnregisteredParser, "No parser registered for #{model_name}." unless parser

        # Pass self instead of @endpoint so nested entities can call expose_params_from_model
        parsed_response = parser.new(model, self).call
        definition = GrapeSwagger::DocMethods::BuildModelDefinition.parse_params_from_model(
          parsed_response, model, model_name
        )

        @definitions[model_name] = definition

        # Recursively expose nested models referenced by $ref
        expose_nested_refs(definition)

        # Convert definition to schema and add to components
        schema = @schema_builder.build_from_definition(definition)
        schema.canonical_name = model_name
        @spec.components.add_schema(model_name, schema)

        model_name
      end

      # Recursively find and expose $ref references in a definition
      def expose_nested_refs(obj)
        return unless obj.is_a?(Hash)

        # Check for $ref at current level
        if obj['$ref'] || obj[:$ref]
          ref = obj['$ref'] || obj[:$ref]
          ref_name = ref.split('/').last
          # Only expose if not already defined
          unless @definitions.key?(ref_name)
            # Try to find the model class and expose it
            begin
              klass = Object.const_get(ref_name)
              expose_params_from_model(klass) if GrapeSwagger.model_parsers.find(klass)
            rescue NameError
              # Class not found - that's ok, might be defined elsewhere
            end
          end
        end

        # Recursively check nested structures
        obj.each_value do |value|
          if value.is_a?(Hash)
            expose_nested_refs(value)
          elsif value.is_a?(Array)
            value.each { |item| expose_nested_refs(item) if item.is_a?(Hash) }
          end
        end
      end
    end
  end
  end
end
