module GrapeSwagger
  module DocMethods
    class TagNameDescription
      class << self
        def build(options = {})
          target_class = options[:target_class]
          namespaces = target_class.combined_namespaces
          namespace_routes = target_class.combined_namespace_routes

          namespace_routes.keys.map do |local_route|
            next if namespace_routes[local_route].map(&:route_hidden).all? { |value| value.respond_to?(:call) ? value.call : value }

            original_namespace_name = target_class.combined_namespace_identifiers.key?(local_route) ? target_class.combined_namespace_identifiers[local_route] : local_route
            description = namespaces[original_namespace_name] && namespaces[original_namespace_name].options[:desc]
            description ||= "Operations about #{original_namespace_name.pluralize}"

            {
              name: local_route,
              description: description
            }
          end.compact
        end
      end
    end
  end
end
