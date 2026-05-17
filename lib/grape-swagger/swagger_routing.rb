# frozen_string_literal: true

module GrapeSwagger
  module SwaggerRouting
    private

    def combine_routes(app, doc_klass)
      app.routes.each_with_object({}) do |route, combined_routes|
        route_path = route.path
        route_match = route_path.split(/^.*?#{route.prefix}/).last
        next unless route_match

        # want to match emojis ... ;)
        # route_match = route_match
        #   .match('\/([\p{Alnum}p{Emoji}\-\_]*?)[\.\/\(]') || route_match.match('\/([\p{Alpha}\p{Emoji}\-\_]*)$')
        route_match = route_match.match('\/([\p{Alnum}\-\_]*?)[\.\/\(]') || route_match.match('\/([\p{Alpha}\-\_]*)$')
        next unless route_match

        resource = route_match.captures.first
        resource = '/' if resource.empty?
        combined_routes[resource] ||= []
        next if doc_klass.hide_documentation_path && route.path.match(/#{doc_klass.mount_path}($|\/|\(\.)/)

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
      # iterate over each single namespace
      namespaces.each_key do |name, _|
        # get the parent route for the namespace
        parent_route_name = extract_parent_route(name)
        parent_route = routes[parent_route_name]
        # fetch all routes that are within the current namespace
        namespace_routes = determine_namespaced_routes(name, parent_route, routes)

        # default case when not explicitly specified or nested == true
        standalone_namespaces = namespaces.reject do |_, ns|
          !ns.options.key?(:swagger) ||
            !ns.options[:swagger].key?(:nested) ||
            ns.options[:swagger][:nested] != false
        end

        parent_standalone_namespaces = standalone_namespaces.select { |ns_name, _| name.start_with?(ns_name) }
        # add only to the main route
        # if the namespace is not within any other namespace appearing as standalone resource
        # rubocop:disable Style/Next
        if parent_standalone_namespaces.empty?
          # default option, append namespace methods to parent route
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
      patterns = Enumerator.new do |yielder|
        yielder << "/#{name}"
        yielder << "/:version/#{name}"
      end

      patterns.any? { |p| route.namespace == p }
    end

    def route_path_start_with?(route, name)
      patterns = Enumerator.new do |yielder|
        if route.prefix
          yielder << "/#{route.prefix}/#{name}"
          yielder << "/#{route.prefix}/:version/#{name}"
        else
          yielder << "/#{name}"
          yielder << "/:version/#{name}"
        end
      end

      patterns.any? { |p| route.path.start_with?(p) }
    end
  end
end
