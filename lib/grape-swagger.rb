# frozen_string_literal: true

require 'grape'

require 'grape-swagger/instance'

require 'grape-swagger/errors'
require 'grape-swagger/version'
require 'grape-swagger/model_parsers'
require 'grape-swagger/swagger_2/endpoint'
require 'grape-swagger/openapi_3/endpoint'
require 'grape-swagger/openapi_3/doc_methods'
require 'grape-swagger/swagger_2/doc_methods'

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
    app.routes.each_with_object({}) do |route, combined_routes|
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

module SwaggerDocumentationAdder
  attr_accessor :combined_namespaces, :combined_routes, :combined_namespace_routes

  include SwaggerRouting

  def add_swagger_documentation(options = {})
    options = { target_class: self }.merge(options)
    version_for(options)
    @target_class = options[:target_class]
    documentation_class = create_documentation_class(options[:openapi_version])
    auth_wrapper = options[:endpoint_auth_wrapper] || Class.new

    use auth_wrapper if auth_wrapper.method_defined?(:before) && !middleware.flatten.include?(auth_wrapper)

    documentation_class.setup(options)
    mount(documentation_class)

    combined_routes = combine_routes(@target_class, documentation_class)
    combined_namespaces = combine_namespaces(@target_class)
    combined_namespace_routes = combine_namespace_routes(combined_namespaces, combined_routes)
    exclusive_route_keys = combined_routes.keys - combined_namespaces.keys
    @target_class.combined_namespace_routes = combined_namespace_routes.merge(
      combined_routes.slice(*exclusive_route_keys)
    )
    @target_class.combined_routes = combined_routes
    @target_class.combined_namespaces = combined_namespaces

    endpoint_type = options[:openapi_version] == '3.0' ? Grape::OpenAPI3Endpoint : Grape::Swagger2Endpoint
    set_endpoint_type(@target_class, endpoint_type)
    set_endpoint_type(documentation_class, endpoint_type)

    documentation_class
  end

  private

  def version_for(options)
    options[:version] = version if version
  end

  def set_endpoint_type(app, klass)
    app.endpoints.each do |endpoint|
      endpoint.class.include(klass)
      set_endpoint_type(endpoint.options[:app], klass) if endpoint.options[:app]
    end
  end

  def combine_namespaces(app)
    combined_namespaces = {}
    endpoints = app.endpoints.clone

    while endpoints.any?
      endpoint = endpoints.shift

      endpoints.push(*endpoint.options[:app].endpoints) if endpoint.options[:app]
      ns = endpoint.namespace_stackable(:namespace).last
      next unless ns

      # use the full namespace here (not the latest level only)
      # and strip leading slash
      mount_path = (endpoint.namespace_stackable(:mount_path) || []).join('/')
      full_namespace = (mount_path + endpoint.namespace).sub(/\/{2,}/, '/').sub(/^\//, '')
      combined_namespaces[full_namespace] = ns
    end

    combined_namespaces
  end

  def create_documentation_class(openapi_version)
    Class.new(GrapeInstance) do
      if openapi_version == '3.0'
        extend GrapeOpenAPI::DocMethods
      else
        extend GrapeSwagger::DocMethods
      end
    end
  end
end

GrapeInstance.extend(SwaggerDocumentationAdder)
