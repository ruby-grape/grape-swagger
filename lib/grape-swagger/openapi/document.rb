# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # Root specification container - version agnostic.
    class Document
      attr_accessor :info, :servers, :paths, :components,
                    :security, :tags, :external_docs,
                    :extensions,
                    # OpenAPI 3.1 specific
                    :webhooks, :json_schema_dialect,
                    # Swagger 2.0 specific
                    :host, :base_path, :schemes,
                    :produces, :consumes

      def initialize
        @info = Info.new
        @servers = []
        @paths = {}
        @webhooks = {}
        @components = Components.new
        @tags = []
        @extensions = {}
        @schemes = []
      end

      def add_webhook(name, path_item)
        @webhooks[name] = path_item
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
    end
  end
end
