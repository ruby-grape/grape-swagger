require 'singleton'

require_relative 'helpers/handler_helpers'
require_relative 'helpers/parser_helpers'

require 'grape_swagger_handlers'

module GrapeSwaggerCore
  @@combined_routes = {}
  @@documentation_options = {}

  SWAGGER_DEFAULT_OPTIONS = {
    :target_class => nil,
    :mount_path => '/swagger_doc',
    :base_path => nil,
    :api_version => '0.1',
    :markdown => false,
    :hide_documentation_path => false,
    :hide_format => false
  }

  def combined_routes
    @@combined_routes
  end

  def documentation_options
    @@documentation_options
  end

  def add_documentation_options(version, options)
    options = {
      target_class: self,
      api_version: version 
    }.merge(options)
    options = SWAGGER_DEFAULT_OPTIONS.merge(options)
    @@documentation_options[version] = options
  end

  def add_combined_routes(routes)
    routes.each do |route|
      resource = route.route_path.match('\/(\w*?)[\.\/\(]').captures.first
      next if resource.empty?
      resource.downcase!
      version = route.route_version.to_s
      @@combined_routes[version] ||= {}
      @@combined_routes[version][resource] ||= []
      @@combined_routes[version][resource] << route
    end
  end

  def add_swagger_documentation(options={})
    version = routes.first.route_version.to_s
    add_documentation_options(version, options)
    
    documentation_class = create_documentation_class
    documentation_class.register_handlers(documentation_options[version])
    
    mount(documentation_class)

    add_combined_routes(routes)
  end

  def create_documentation_class
    Class.new(Grape::API) do
      include Singleton
      extend GrapeSwaggerHandlers

      class << self
        def name
          @@class_name
        end
      end

      helpers HandlerHelpers
      helpers ParserHelpers
    end
  end
end
