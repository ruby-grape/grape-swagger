# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    # Pure per-route decisions shared by the Swagger 2.0 generator (Endpoint) and the
    # OpenAPI 3.x builder, so the two outputs cannot drift apart.
    module RouteRules
      SUPPORTS_CONSUMES = %i[post put patch].freeze

      class << self
        # `endpoint` resolves the token owner when `options[:token_owner]` is set.
        def hidden_route?(route, options, endpoint)
          route_hidden = route.settings.try(:[], :swagger).try(:[], :hidden)
          hidden_val = route.hidden
          route_hidden = hidden_val unless hidden_val.nil?
          return route_hidden unless route_hidden.is_a?(Proc)

          return route_hidden.call unless options[:token_owner]

          token_owner = GrapeSwagger::TokenOwnerResolver.resolve(endpoint, options[:token_owner])
          GrapeSwagger::TokenOwnerResolver.evaluate_proc(route_hidden, token_owner)
        end

        def hidden_parameter?(value)
          return false if value[:required]

          hidden = value.dig(:documentation, :hidden)
          hidden.is_a?(Proc) ? hidden.call : hidden
        end

        def file_response?(value)
          value.to_s.casecmp('file').zero?
        end

        def produces(route, format)
          produces = route.produces
          return ['application/octet-stream'] if file_response?(route.success) && !produces.present?

          route_mime_types = ProducesConsumes.call(produces) if produces.present?
          route_mime_types.presence || ProducesConsumes.call(format)
        end

        def consumes(route, format)
          return unless SUPPORTS_CONSUMES.include?(route.request_method.downcase.to_sym)

          ProducesConsumes.call(route.settings.dig(:description, :consumes) || format)
        end

        # Explicit route tags win; otherwise the first path segment that is not a prefix or version.
        def tag_names(route, path)
          route.tags.presence || derived_tags(route, path)
        end

        def derived_tags(route, path)
          version = Array(Version.get(route)).map(&:to_s)
          prefix = route.prefix.to_s.split('/').reject(&:empty?)
          Array(
            path.split('{')[0].split('/').reject(&:empty?).delete_if do |i|
              prefix.include?(i) || version.include?(i)
            end.first
          ).presence
        end

        # User-supplied tags replace derived tags of the same name and follow them. Only the merge is shared:
        # Swagger 2.0 derives names from the first operation of each path, OpenAPI 3.x from every operation,
        # and 3.x also emits user tags when the API has no routes.
        def merge_tags(derived_tags, user_tags)
          return derived_tags unless user_tags

          names = user_tags.map { |t| t[:name] }
          derived_tags.reject { |t| names.include?(t[:name]) } + user_tags
        end

        # The `default` response entry from `default_response:`, or nil.
        def default_response_code(route)
          entity = route.default_response
          return if entity.nil?

          code = { code: 'default', message: 'Default Response' }
          if entity.is_a?(Hash)
            code[:message] = entity[:message] || code[:message]
            code[:model] = entity[:model] if entity[:model].present?
          else
            code[:model] = entity
          end
          code
        end
      end
    end
  end
end
