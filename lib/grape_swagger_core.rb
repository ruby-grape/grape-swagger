require 'singleton'

require_relative 'helpers/parser_helpers'
require 'grape_swagger_handlers'

module GrapeSwaggerCore
  @@combined_routes = {}
  SWAGGER_DEFAULTS = {
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
    p "#-- target_class: #{self.name}"
    options = {:target_class => self}.merge(options)
    options = SWAGGER_DEFAULTS.merge(options)
    
    documentation_class = create_documentation_class
    documentation_class.register_handlers(options)
    
    #p "#-- targets class routes", documentation_class.routes
    p "Should mount: #{combined_routes.empty?}" 
    mount(documentation_class)  #if combined_routes.empty?

    add_combined_routes(routes)
    p "#-----------", combined_routes
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

      helpers ParserHelpers
    end
  end
  #end of create_docu
end
