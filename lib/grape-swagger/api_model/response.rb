# frozen_string_literal: true

module GrapeSwagger
  module ApiModel
    # Response definition.
    class Response
      attr_accessor :status_code, :description, :media_types, :headers,
                    :links, :extensions,
                    # Swagger 2.0 specific
                    :schema, :examples

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @media_types ||= []
        @headers ||= {}
        @extensions ||= {}
      end

      def add_media_type(mime_type, schema:, example: nil, examples: nil)
        @media_types << MediaType.new(
          mime_type: mime_type,
          schema: schema,
          example: example,
          examples: examples
        )
      end

      def add_header(name, schema:, description: nil)
        @headers[name] = Header.new(
          name: name,
          schema: schema,
          description: description
        )
      end

      def content
        media_types.each_with_object({}) do |mt, hash|
          hash[mt.mime_type] = mt.to_h
        end
      end

      def to_h
        hash = { description: description || '' }
        hash[:content] = content if media_types.any?
        hash[:headers] = headers.transform_values(&:to_h) if headers.any?
        hash[:links] = links if links&.any?
        extensions.each { |k, v| hash[k] = v } if extensions.any?
        hash
      end

      # Swagger 2.0 style output
      def to_swagger2_h
        hash = { description: description || '' }
        if schema
          hash[:schema] = schema.respond_to?(:to_h) ? schema.to_h : schema
        elsif media_types.any?
          primary = media_types.first
          hash[:schema] = primary.schema.respond_to?(:to_h) ? primary.schema.to_h : primary.schema if primary.schema
        end
        hash[:headers] = headers.transform_values(&:to_swagger2_h) if headers.any?
        hash[:examples] = examples if examples&.any?
        extensions.each { |k, v| hash[k] = v } if extensions.any?
        hash
      end
    end

    # Header definition.
    class Header
      attr_accessor :name, :description, :required, :deprecated,
                    :schema, :style, :explode,
                    :example, :examples, :extensions,
                    # Swagger 2.0 specific
                    :type, :format, :items

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @extensions ||= {}
      end

      def to_h
        hash = {}
        hash[:description] = description if description
        hash[:required] = required if required
        hash[:deprecated] = deprecated if deprecated
        hash[:schema] = schema.respond_to?(:to_h) ? schema.to_h : schema if schema
        hash[:style] = style if style
        hash[:explode] = explode unless explode.nil?
        hash[:example] = example unless example.nil?
        hash[:examples] = examples if examples&.any?
        extensions.each { |k, v| hash[k] = v } if extensions.any?
        hash
      end

      def to_swagger2_h
        hash = {}
        hash[:description] = description if description
        hash[:type] = type || (schema&.type) if type || schema&.type
        hash[:format] = format || (schema&.format) if format || schema&.format
        hash[:items] = items.respond_to?(:to_h) ? items.to_h : items if items
        extensions.each { |k, v| hash[k] = v } if extensions.any?
        hash
      end
    end
  end
end
