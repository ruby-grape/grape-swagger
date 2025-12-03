# frozen_string_literal: true

module GrapeSwagger
  module ApiModel
    # Root specification container - version agnostic.
    class Spec
      attr_accessor :info, :servers, :paths, :components,
                    :security, :tags, :external_docs,
                    :extensions,
                    # Swagger 2.0 specific
                    :host, :base_path, :schemes,
                    :produces, :consumes

      def initialize
        @info = Info.new
        @servers = []
        @paths = {}
        @components = Components.new
        @security = []
        @tags = []
        @extensions = {}
        @schemes = []
      end

      def add_path(path_string, path_item)
        @paths[path_string] = path_item
      end

      def add_tag(tag)
        @tags << tag unless @tags.any? { |t| t.name == tag.name }
      end

      def add_server(server)
        @servers << server
      end

      # OpenAPI 3.x output
      def to_h(version: '3.0')
        hash = { openapi: version_string(version) }
        hash[:info] = info.to_h
        hash[:servers] = servers_for_oas3.map(&:to_h) if servers_for_oas3.any?
        hash[:tags] = tags.map(&:to_h) if tags.any?
        hash[:paths] = paths.transform_values(&:to_h) if paths.any?
        hash[:components] = components.to_h unless components.empty?
        hash[:security] = security if security.any?
        hash[:externalDocs] = external_docs.to_h if external_docs
        extensions.each { |k, v| hash[k] = v } if extensions.any?
        hash
      end

      # Swagger 2.0 output
      def to_swagger2_h
        hash = { swagger: '2.0' }
        hash[:info] = swagger2_info
        hash[:host] = host if host
        hash[:basePath] = base_path if base_path
        hash[:schemes] = schemes if schemes.any?
        hash[:produces] = produces if produces&.any?
        hash[:consumes] = consumes if consumes&.any?
        hash[:tags] = tags.map(&:to_h) if tags.any?
        hash[:paths] = paths.transform_values(&:to_swagger2_h) if paths.any?
        hash[:definitions] = components.definitions_h if components.schemas.any?
        hash[:securityDefinitions] = components.security_definitions_h if components.security_schemes.any?
        hash[:security] = security if security.any?
        hash[:externalDocs] = external_docs.to_h if external_docs
        extensions.each { |k, v| hash[k] = v } if extensions.any?
        hash.compact
      end

      private

      def version_string(version)
        case version.to_s
        when '3.0', '3.0.0', '3.0.3' then '3.0.3'
        when '3.1', '3.1.0' then '3.1.0'
        else '3.0.3'
        end
      end

      def servers_for_oas3
        return servers if servers.any?
        return [] unless host

        # Build servers from Swagger 2.0 host/basePath/schemes
        (schemes.presence || ['https']).map do |scheme|
          Server.from_swagger2(host: host, base_path: base_path, scheme: scheme)
        end
      end

      def swagger2_info
        # Remove license identifier for Swagger 2.0
        info_hash = info.to_h
        if info_hash[:license].is_a?(Hash)
          info_hash[:license] = info_hash[:license].reject { |k, _| k == :identifier }
          info_hash[:license] = nil if info_hash[:license].empty?
        end
        info_hash.compact
      end
    end
  end
end
