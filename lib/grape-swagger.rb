require 'grape'
require 'grape-swagger/version'
require 'grape-swagger/endpoint'
require 'grape-swagger/errors'
require 'grape-swagger/doc_methods/produces'
require 'grape-swagger/doc_methods/data_type'
require 'grape-swagger/doc_methods'
require 'grape-swagger/markdown/kramdown_adapter'
require 'grape-swagger/markdown/redcarpet_adapter'

require 'awesome_print'

module Grape
  class API
    class << self
      attr_accessor :combined_routes, :combined_namespaces, :combined_namespace_routes, :combined_namespace_identifiers

      def add_swagger_documentation(options = {})
        documentation_class = create_documentation_class

        version_for(options)
        options = { target_class: self }.merge(options)
        @target_class = options[:target_class]

        documentation_class.setup(options)
        mount(documentation_class)

        @target_class.combined_routes = {}
        combine_routes(@target_class, documentation_class)

        @target_class.combined_namespaces = {}
        combine_namespaces(@target_class)

        @target_class.combined_namespace_routes = {}
        @target_class.combined_namespace_identifiers = {}
        combine_namespace_routes(@target_class.combined_namespaces)

        exclusive_route_keys = @target_class.combined_routes.keys - @target_class.combined_namespaces.keys
        exclusive_route_keys.each { |key| @target_class.combined_namespace_routes[key] = @target_class.combined_routes[key] }
        documentation_class
      end

      private

      def version_for(options)
        options[:version] = version if version
      end

      def combine_routes(app, doc_klass)
        app.routes.each do |route|
          route_path = route.route_path
          route_match = route_path.split(/^.*?#{route.route_prefix.to_s}/).last
          next unless route_match
          route_match = route_match.match('\/([\w|-]*?)[\.\/\(]') || route_match.match('\/([\w|-]*)$')
          next unless route_match
          resource = route_match.captures.first
          next if resource.empty?
          resource.downcase!
          @target_class.combined_routes[resource] ||= []
          next if doc_klass.hide_documentation_path && route.route_path.match(/#{doc_klass.mount_path}($|\/|\(\.)/)
          @target_class.combined_routes[resource] << route
        end
      end

      def combine_namespaces(app)
        app.endpoints.each do |endpoint|
          ns = if endpoint.respond_to?(:namespace_stackable)
                 endpoint.namespace_stackable(:namespace).last
               else
                 endpoint.settings.stack.last[:namespace]
               end
          # use the full namespace here (not the latest level only)
          # and strip leading slash
          @target_class.combined_namespaces[endpoint.namespace.sub(/^\//, '')] = ns if ns

          combine_namespaces(endpoint.options[:app]) if endpoint.options[:app]
        end
      end

      def combine_namespace_routes(namespaces)
        # iterate over each single namespace
        namespaces.each do |name, namespace|
          # get the parent route for the namespace
          parent_route_name = name.match(%r{^/?([^/]*).*$})[1]
          parent_route = @target_class.combined_routes[parent_route_name]
          # fetch all routes that are within the current namespace
          namespace_routes = parent_route.reject do |route|
            !route_path_start_with?(route, name) || !route_instance_variable_equals?(route, name)
          end

          if namespace.options.key?(:swagger) && namespace.options[:swagger][:nested] == false
            # Namespace shall appear as standalone resource, use specified name or use normalized path as name
            identifier =  if namespace.options[:swagger].key?(:name)
                            name.tr(' ', '-')
                          else
                            name.tr('_', '-').gsub(/\//, '_')
                          end
            @target_class.combined_namespace_identifiers[identifier] = name
            @target_class.combined_namespace_routes[identifier] = namespace_routes

            # # get all nested namespaces below the current namespace
            sub_namespaces = standalone_sub_namespaces(name, namespaces)
            sub_routes = sub_routes_from(parent_route, sub_namespaces)
            @target_class.combined_namespace_routes[identifier].push(*sub_routes)
          else
            # default case when not explicitly specified or nested == true
            standalone_namespaces = namespaces.reject do |_, ns|
              !ns.options.key?(:swagger) ||
                !ns.options[:swagger].key?(:nested) ||
                ns.options[:swagger][:nested] != false
            end

            parent_standalone_namespaces = standalone_namespaces.reject { |ns_name, _| !name.start_with?(ns_name) }
            # add only to the main route if the namespace is not within any other namespace appearing as standalone resource
            if parent_standalone_namespaces.empty?
              # default option, append namespace methods to parent route
              @target_class.combined_namespace_routes[parent_route_name] = [] unless @target_class.combined_namespace_routes.key?(parent_route_name)
              @target_class.combined_namespace_routes[parent_route_name].push(*namespace_routes)
            end
          end
        end
      end

      def sub_routes_from(parent_route, sub_namespaces)
        sub_ns_paths = sub_namespaces.collect { |ns_name, _| ["/#{ns_name}", "/:version/#{ns_name}"] }
        sub_routes = parent_route.reject do |route|
          parent_namespace = route_instance_variable(route)
          !sub_ns_paths.assoc(parent_namespace) && !sub_ns_paths.rassoc(parent_namespace)
        end

        sub_routes
      end

      def route_instance_variable(route)
        route.instance_variable_get(:@options)[:namespace]
      end

      def route_instance_variable_equals?(route, name)
        route_instance_variable(route) == "/#{name}" ||
          route_instance_variable(route) == "/:version/#{name}"
      end

      def route_path_start_with?(route, name)
        route_prefix = route.route_prefix ? "/#{route.route_prefix}/#{name}" : "/#{name}"
        route_versioned_prefix = route.route_prefix ? "/#{route.route_prefix}/:version/#{name}" : "/:version/#{name}"

        route.route_path.start_with?(route_prefix, route_versioned_prefix)
      end

      def standalone_sub_namespaces(name, namespaces)
        # assign all nested namespace routes to this resource, too
        # (unless they are assigned to another standalone namespace themselves)
        sub_namespaces = {}
        # fetch all namespaces that are children of the current namespace
        namespaces.each { |ns_name, ns| sub_namespaces[ns_name] = ns if ns_name.start_with?(name) && ns_name != name }
        # remove the sub namespaces if they are assigned to another standalone namespace themselves
        sub_namespaces.each do |sub_name, sub_ns|
          # skip if sub_ns is standalone, too
          next unless sub_ns.options.key?(:swagger) && sub_ns.options[:swagger][:nested] == false
          # remove all namespaces that are nested below this standalone sub_ns
          sub_namespaces.each { |sub_sub_name, _| sub_namespaces.delete(sub_sub_name) if sub_sub_name.start_with?(sub_name) }
        end
        sub_namespaces
      end

      def create_documentation_class
        Class.new(Grape::API) do
          extend GrapeSwagger::DocMethods
        end
      end
    end
  end
end
