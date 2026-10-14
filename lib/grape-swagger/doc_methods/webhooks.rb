# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    # Adds webhooks from configuration to an OpenAPI 3.1 document.
    #
    # The configuration is already shaped like an OpenAPI Path Item Object, so it is passed through
    # unchanged except that keys are symbolized (definitions loaded from YAML or JSON arrive as
    # strings) and Swagger 2.0 style `#/definitions/` references point to `#/components/schemas/`.
    module Webhooks
      class << self
        def apply(spec, webhooks_config)
          return unless webhooks_config.is_a?(Hash)

          webhooks_config.each do |name, webhook_def|
            # The path item's fields are exported verbatim as its extensions.
            path_item = GrapeSwagger::OpenAPI::PathItem.new(extensions: rewrite_refs(webhook_def.deep_symbolize_keys))
            spec.add_webhook(name.to_s, path_item)
          end
        end

        private

        def rewrite_refs(value)
          case value
          when Hash
            value.to_h do |key, nested|
              if key.to_s == '$ref' && nested.is_a?(String)
                [key, nested.sub('#/definitions/', '#/components/schemas/')]
              else
                [key, rewrite_refs(nested)]
              end
            end
          when Array then value.map { |nested| rewrite_refs(nested) }
          else value
          end
        end
      end
    end
  end
end
