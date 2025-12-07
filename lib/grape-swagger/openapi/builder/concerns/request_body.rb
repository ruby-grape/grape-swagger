# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds OpenAPI request bodies from Grape route parameters
      module RequestBodyBuilder # rubocop:disable Metrics/ModuleLength
        def build_request_body_from_params(operation, body_params, consumes, route, path)
          request_body = OpenAPI::RequestBody.new
          request_body.required = body_params.any? { |bp| bp[:options][:required] }
          request_body.description = route.description

          schema = build_nested_body_schema(body_params, route)

          definition_name = GrapeSwagger::DocMethods::OperationId.build(route, path)
          @definitions[definition_name] = { type: 'object' }
          @spec.components.add_schema(definition_name, schema)

          ref_schema = OpenAPI::Schema.new
          ref_schema.canonical_name = definition_name

          content_types = consumes || ['application/json']
          content_types.each do |content_type|
            request_body.add_media_type(content_type, schema: ref_schema)
          end

          operation.request_body = request_body
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

        private

        def build_nested_body_schema(body_params, route)
          schema = OpenAPI::Schema.new(type: 'object')
          schema.description = route.description

          top_level = []
          nested = []
          body_params.each do |bp|
            if bp[:name].to_s.include?('[')
              nested << bp
            else
              top_level << bp
            end
          end

          top_level.each do |bp|
            name = bp[:name].to_s
            prop_schema = build_param_schema(bp[:options])

            related_nested = nested.select { |n| n[:name].to_s.start_with?("#{name}[") }
            build_nested_properties(prop_schema, name, related_nested) if related_nested.any?

            schema.add_property(name, prop_schema)
            schema.mark_required(name) if bp[:options][:required]
          end

          schema
        end

        def build_nested_properties(parent_schema, parent_name, nested_params)
          children = group_nested_params_by_child(parent_name, nested_params)

          children.each do |child_name, child_params|
            direct_param = child_params.find { |p| p[:name].to_s == "#{parent_name}[#{child_name}]" }
            next unless direct_param

            child_schema = build_param_schema(direct_param[:options])
            process_deeper_nested(child_schema, parent_name, child_name, child_params)
            add_child_to_parent(parent_schema, child_name, child_schema, direct_param[:options][:required])
          end
        end

        def group_nested_params_by_child(parent_name, nested_params)
          nested_params.each_with_object({}) do |np, children|
            remainder = np[:name].to_s.sub("#{parent_name}[", '')
            child_name = remainder.include?('][') ? remainder.split('][').first.chomp(']') : remainder.chomp(']')
            children[child_name] ||= []
            children[child_name] << np
          end
        end

        def process_deeper_nested(child_schema, parent_name, child_name, child_params)
          deeper_nested = child_params.reject { |p| p[:name].to_s == "#{parent_name}[#{child_name}]" }
          return unless deeper_nested.any?

          nested_path = "#{parent_name}[#{child_name}]"
          target_schema = child_schema.type == 'array' && child_schema.items ? child_schema.items : child_schema
          build_nested_properties(target_schema, nested_path, deeper_nested)
        end

        def add_child_to_parent(parent_schema, child_name, child_schema, required)
          if parent_schema.type == 'array' && parent_schema.items
            add_property_to_array_items(parent_schema.items, child_name, child_schema, required)
          else
            add_property_to_object(parent_schema, child_name, child_schema, required)
          end
        end

        def add_property_to_array_items(items_schema, child_name, child_schema, required)
          items_schema.type = 'object'
          items_schema.format = nil
          items_schema.add_property(child_name, child_schema)
          items_schema.mark_required(child_name) if required
        end

        def add_property_to_object(parent_schema, child_name, child_schema, required)
          convert_to_object_if_needed(parent_schema)
          parent_schema.add_property(child_name, child_schema)
          parent_schema.mark_required(child_name) if required
        end

        def convert_to_object_if_needed(schema)
          return unless schema.type && !%w[object array].include?(schema.type)

          schema.type = 'object'
          schema.format = nil
        end
      end
    end
  end
end
