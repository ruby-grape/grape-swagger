# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # Version-agnostic JSON Schema representation.
    # Used for request/response bodies, parameters, and component schemas.
    class Schema
      attr_accessor :type, :format, :properties, :items, :additional_properties,
                    :required, :enum, :nullable, :default,
                    :minimum, :maximum, :exclusive_minimum, :exclusive_maximum,
                    :min_length, :max_length, :min_items, :max_items,
                    :pattern, :multiple_of,
                    :all_of, :one_of, :any_of, :not,
                    :discriminator,
                    :canonical_name, :description, :example, :examples,
                    :read_only, :write_only, :deprecated,
                    :extensions,
                    # OpenAPI 3.1 specific
                    :json_schema, :content_media_type, :content_encoding

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @properties ||= {}
        @required ||= []
        @extensions ||= {}
      end

      def add_property(name, schema)
        @properties[name.to_s] = schema
      end

      def mark_required(name)
        @required << name.to_s unless @required.include?(name.to_s)
      end
    end
  end
end
