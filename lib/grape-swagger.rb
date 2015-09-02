require 'grape'
require 'grape-swagger/version'
require 'grape-swagger/errors'
require 'grape-swagger/doc_methods'
require 'grape-swagger/markdown'
require 'grape-swagger/markdown/kramdown_adapter'
require 'grape-swagger/markdown/redcarpet_adapter'

module Grape
  class API
    class << self
      attr_accessor :combined_routes, :combined_namespaces, :combined_namespace_routes, :combined_namespace_identifiers
      attr_accessor :endpoint_mapping

      def add_swagger_documentation(options = {})
        documentation_class = create_documentation_class

        options = { target_class: self }.merge(options)
        @target_class = options[:target_class]

        documentation_class.setup(options)
        mount(documentation_class)

        @target_class.combined_routes = {}
        @target_class.routes.each do |route|
          route_path = route.route_path
          route_match = route_path.split(/^.*?#{route.route_prefix.to_s}/).last
          next unless route_match
          route_match = route_match.match('\/([\w|-]*?)[\.\/\(]') || route_match.match('\/([\w|-]*)$')
          next unless route_match
          resource = route_match.captures.first
          next if resource.empty?
          resource.downcase!
          @target_class.combined_routes[resource] ||= []
          next if documentation_class.hide_documentation_path && route.route_path.match(/#{documentation_class.mount_path}($|\/|\(\.)/)
          @target_class.combined_routes[resource] << route
        end

        @target_class.endpoint_mapping = {}
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

          endpoint.routes.each do |route|
            @target_class.endpoint_mapping[route.to_s.sub('(.:format)', '')] = endpoint
          end

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
          namespace_routes = parent_route.collect do |route|
            route if (route.route_path.start_with?(route.route_prefix ? "/#{route.route_prefix}/#{name}" : "/#{name}") || route.route_path.start_with?((route.route_prefix ? "/#{route.route_prefix}/:version/#{name}" : "/:version/#{name}"))) &&
                     (route.instance_variable_get(:@options)[:namespace] == "/#{name}" || route.instance_variable_get(:@options)[:namespace] == "/:version/#{name}")
          end.compact

          if namespace.options.key?(:swagger) && namespace.options[:swagger][:nested] == false
            # Namespace shall appear as standalone resource, use specified name or use normalized path as name
            if namespace.options[:swagger].key?(:name)
              identifier = namespace.options[:swagger][:name].tr(' ', '-')
            else
              identifier = name.tr('_', '-').gsub(/\//, '_')
            end
            @target_class.combined_namespace_identifiers[identifier] = name
            @target_class.combined_namespace_routes[identifier] = namespace_routes

            # get all nested namespaces below the current namespace
            sub_namespaces = standalone_sub_namespaces(name, namespaces)
            # convert namespace to route names
            sub_ns_paths = sub_namespaces.collect { |ns_name, _| "/#{ns_name}" }
            sub_ns_paths_versioned = sub_namespaces.collect { |ns_name, _| "/:version/#{ns_name}" }
            # get the actual route definitions for the namespace path names
            sub_routes = parent_route.collect do |route|
              route if sub_ns_paths.include?(route.instance_variable_get(:@options)[:namespace]) || sub_ns_paths_versioned.include?(route.instance_variable_get(:@options)[:namespace])
            end.compact
            # add all determined routes of the sub namespaces to standalone resource
            @target_class.combined_namespace_routes[identifier].push(*sub_routes)
          else
            # default case when not explicitly specified or nested == true
            standalone_namespaces = namespaces.reject { |_, ns| !ns.options.key?(:swagger) || !ns.options[:swagger].key?(:nested) || ns.options[:swagger][:nested] != false }
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

      def get_non_nested_params(params)
        # Duplicate the params as we are going to modify them
        dup_params = params.each_with_object({}) do |(param, value), dparams|
          dparams[param] = value.dup
        end

        dup_params.reject do |param, value|
          is_nested_param = /^#{ Regexp.quote param }\[.+\]$/
          0 < dup_params.count do |p, _|
            match = p.match(is_nested_param)
            dup_params[p][:required] = false if match && !value[:required]
            match
          end
        end
      end

      def parse_array_params(params)
        modified_params = {}
        array_param = nil
        params.each_key do |k|
          if params[k].is_a?(Hash) && params[k][:type] == 'Array'
            array_param = k
            modified_params[k] = params[k]
          else
            new_key = k
            unless array_param.nil?
              if k.to_s.start_with?(array_param.to_s + '[')
                new_key = array_param.to_s + '[]' + k.to_s.split(array_param)[1]
                modified_params.delete array_param
              end
            end
            modified_params[new_key] = params[k]
          end
        end
        modified_params
      end

      def parse_enum_or_range_values(values)
        case values
        when Range
          parse_range_values(values) if values.first.is_a?(Integer)
        when Proc
          values_result = values.call
          if values_result.is_a?(Range) && values_result.first.is_a?(Integer)
            parse_range_values(values_result)
          else
            { enum: values_result }
          end
        else
          { enum: values } if values
        end
      end

      def parse_range_values(values)
        { minimum: values.first, maximum: values.last }
      end

      def create_documentation_class
        Class.new(Grape::API) do
          extend GrapeSwagger::DocMethods
        end
      end
    end
  end
end
