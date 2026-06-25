# frozen_string_literal: true

module GrapeSwagger
  module SwaggerRouting
    private

    def combine_routes(app, doc_klass)
      app.routes.each_with_object({}) do |route, combined_routes|
        route_path = route.path
        route_match = route_path.split(/^.*?#{Regexp.escape(route.prefix.to_s)}/).last
        next unless route_match

        route_match = route_match.match('\/([\p{Alnum}\-\_]*?)[\.\/\(]') || route_match.match('\/([\p{Alpha}\-\_]*)$')
        next unless route_match

        resource = route_match.captures.first
        resource = '/' if resource.empty?
        combined_routes[resource] ||= []
        next if doc_klass.hide_documentation_path && route.path.match(/#{Regexp.escape(doc_klass.mount_path)}($|\/|\(\.)/)

        combined_routes[resource] << route
      end
    end

    def determine_namespaced_routes(name, parent_route, routes)
      return routes.values.flatten if parent_route.nil?

      parent_route.select do |route|
        route_path_start_with?(route, name) || route_namespace_equals?(route, name)
      end
    end

    def combine_namespace_routes(namespaces, routes)
      combined_namespace_routes = {}
      standalone_namespaces = namespaces.select { |_, ns| ns.options.dig(:swagger, :nested) == false }

      namespaces.each_key do |name|
        parent_route_name = extract_parent_route(name)
        parent_route = routes[parent_route_name]
        namespace_routes = determine_namespaced_routes(name, parent_route, routes)

        parent_standalone_namespaces = standalone_namespaces.select do |ns_name, _|
          name == ns_name || name.start_with?("#{ns_name}/")
        end
        # rubocop:disable Style/Next
        if parent_standalone_namespaces.empty?
          combined_namespace_routes[parent_route_name] ||= []
          combined_namespace_routes[parent_route_name].push(*namespace_routes)
        end
        # rubocop:enable Style/Next
      end

      combined_namespace_routes
    end

    def extract_parent_route(name)
      route_name = name.match(%r{^/?([^/]*).*$})[1]
      return route_name unless route_name.include? ':'

      matches = name.match(/\/\p{Alpha}+/)
      matches.nil? ? route_name : matches[0].delete('/')
    end

    def route_namespace_equals?(route, name)
      ["/#{name}", "/:version/#{name}"].any? { |p| route.namespace == p }
    end

    def route_path_start_with?(route, name)
      # String#start_with? is a literal prefix check, so Regexp.escape is not needed here.
      patterns = if route.prefix.to_s.empty?
                   ["/#{name}", "/:version/#{name}"]
                 else
                   ["/#{route.prefix}/#{name}", "/#{route.prefix}/:version/#{name}"]
                 end

      patterns.any? { |p| route.path.start_with?(p) }
    end
  end
end
