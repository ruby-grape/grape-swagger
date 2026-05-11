# frozen_string_literal: true

module SwaggerDocumentationAdder
  attr_accessor :combined_namespaces, :combined_routes, :combined_namespace_routes

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

    combined_routes = combine_routes(@target_class, documentation_class)
    combined_namespaces = combine_namespaces(@target_class)
    combined_namespace_routes = combine_namespace_routes(combined_namespaces, combined_routes)
    exclusive_route_keys = combined_routes.keys - combined_namespaces.keys
    @target_class.combined_namespace_routes = combined_namespace_routes.merge(
      combined_routes.slice(*exclusive_route_keys)
    )
    @target_class.combined_routes = combined_routes
    @target_class.combined_namespaces = combined_namespaces

    documentation_class
  end

  private

  def version_for(options)
    options[:version] = version if version
  end

  def combine_namespaces(app)
    combined_namespaces = {}
    endpoints = app.endpoints.clone

    while endpoints.any?
      endpoint = endpoints.shift

      endpoints.push(*endpoint.options[:app].endpoints) if endpoint.options[:app]
      namespace_stackable = endpoint.inheritable_setting.namespace_stackable
      ns = (namespace_stackable[:namespace] || []).last
      next unless ns

      # use the full namespace here (not the latest level only)
      # and strip leading slash
      mount_path = (namespace_stackable[:mount_path] || []).join('/')
      full_namespace = (mount_path + endpoint.namespace).sub(/\/{2,}/, '/').sub(/^\//, '')
      combined_namespaces[full_namespace] = ns
    end

    combined_namespaces
  end

  def create_documentation_class
    Class.new(GrapeInstance) do
      extend GrapeSwagger::DocMethods
    end
  end
end
