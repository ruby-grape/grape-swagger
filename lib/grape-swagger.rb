# frozen_string_literal: true

require 'grape'

require 'grape-swagger/instance'

require 'grape-swagger/version'
require 'grape-swagger/endpoint'
require 'grape-swagger/errors'

require 'grape-swagger/doc_methods'
require 'grape-swagger/model_parsers'

module GrapeSwagger
  class << self
    def model_parsers
      @model_parsers ||= GrapeSwagger::ModelParsers.new
    end
  end
  autoload :Rake, 'grape-swagger/rake/oapi_tasks'
end

module SwaggerRouting
  private

  def combine_routes(app, doc_klass)
    app.routes.each do |route|
      route_path = route.path
      route_match = route_path.split(/^.*?#{route.prefix}/).last
      next unless route_match

      # want to match emojis … ;)
      # route_match = route_match
      #   .match('\/([\p{Alnum}p{Emoji}\-\_]*?)[\.\/\(]') || route_match.match('\/([\p{Alpha}\p{Emoji}\-\_]*)$')
      route_match = route_match.match('\/([\p{Alnum}\-\_]*?)[\.\/\(]') || route_match.match('\/([\p{Alpha}\-\_]*)$')
      next unless route_match

      resource = route_match.captures.first
      resource = '/' if resource.empty?
      @target_class.combined_routes[resource] ||= []
      next if doc_klass.hide_documentation_path && route.path.match(/#{doc_klass.mount_path}($|\/|\(\.)/)

      @target_class.combined_routes[resource] << route
    end
  end

  def determine_namespaced_routes(name, parent_route)
    if parent_route.nil?
      @target_class.combined_routes.values.flatten
    else
      parent_route.reject do |route|
        !route_path_start_with?(route, name) || !route_instance_variable_equals?(route, name)
      end
    end
  end

  def combine_namespace_routes(namespaces)
    # iterate over each single namespace
    namespaces.each_key do |name, _|
      # get the parent route for the namespace
      parent_route_name = extract_parent_route(name)
      parent_route = @target_class.combined_routes[parent_route_name]
      # fetch all routes that are within the current namespace
      namespace_routes = determine_namespaced_routes(name, parent_route)

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
        parent_route = @target_class.combined_namespace_routes.key?(parent_route_name)
        @target_class.combined_namespace_routes[parent_route_name] = [] unless parent_route
        @target_class.combined_namespace_routes[parent_route_name].push(*namespace_routes)
      end
      # rubocop:enable Style/Next
    end
  end

  def extract_parent_route(name)
    route_name = name.match(%r{^/?([^/]*).*$})[1]
    return route_name unless route_name.include? ':'

    matches = name.match(/\/\p{Alpha}+/)
    matches.nil? ? route_name : matches[0].delete('/')
  end

  def route_instance_variable(route)
    route.instance_variable_get(:@options)[:namespace]
  end

  def route_instance_variable_equals?(route, name)
    route_instance_variable(route) == "/#{name}" ||
      route_instance_variable(route) == "/:version/#{name}"
  end

  def route_path_start_with?(route, name)
    route_prefix = route.prefix ? "/#{route.prefix}/#{name}" : "/#{name}"
    route_versioned_prefix = route.prefix ? "/#{route.prefix}/:version/#{name}" : "/:version/#{name}"

    route.path.start_with?(route_prefix, route_versioned_prefix)
  end
end

module SwaggerDocumentationAdder
  attr_accessor :combined_namespaces, :combined_namespace_identifiers, :combined_routes, :combined_namespace_routes

  include SwaggerRouting

  def add_swagger_documentation(options = {})
    documentation_class = create_documentation_class

    version_for(options)
    options = { target_class: self }.merge(options)
    @target_class = options[:target_class]
    auth_wrapper = options[:endpoint_auth_wrapper] || Class.new

    use auth_wrapper if auth_wrapper.method_defined?(:before) && !middleware.flatten.include?(auth_wrapper)

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
    exclusive_route_keys.each do |key|
      @target_class.combined_namespace_routes[key] = @target_class.combined_routes[key]
    end
    documentation_class
  end

  private

  def version_for(options)
    options[:version] = version if version
  end

  def combine_namespaces(app)
    app.endpoints.each do |endpoint|
      ns = endpoint.namespace_stackable(:namespace).last

      # use the full namespace here (not the latest level only)
      # and strip leading slash
      mount_path = (endpoint.namespace_stackable(:mount_path) || []).join('/')
      full_namespace = (mount_path + endpoint.namespace).sub(/\/{2,}/, '/').sub(/^\//, '')
      @target_class.combined_namespaces[full_namespace] = ns if ns

      combine_namespaces(endpoint.options[:app]) if endpoint.options[:app]
    end
  end

  def create_documentation_class
    Class.new(GrapeInstance) do
      extend GrapeSwagger::DocMethods
    end
  end
end

GrapeInstance.extend(SwaggerDocumentationAdder)
