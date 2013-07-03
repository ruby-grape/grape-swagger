=begin
  GrapeSwaggerHandlers module includes functions that
  register handlers for GrapeSwagger doc views.
=end

module GrapeSwaggerHandlers
	def register_handlers(options)
    @@target_class = options[:target_class]
    @@mount_path = options[:mount_path]
    @@class_name = options[:class_name] || options[:mount_path].gsub('/','')
    @@markdown = options[:markdown]
    @@hide_documentation_path = options[:hide_documentation_path]
    @@hide_format = options[:hide_format]
    @@api_version = options[:api_version]

    @@base_path = options[:base_path]

		register_root_handler
    register_resource_handler
	end

	def register_root_handler()
	    desc 'Swagger compatible API description'
	    get @@mount_path do
	      header['Access-Control-Allow-Origin'] = '*'
	      header['Access-Control-Request-Method'] = '*'
	        
        requested_api_version = params[:route_info].route_version
        p "#--- Requested API Version: #{requested_api_version}"
       
        routes = @@target_class::combined_routes[requested_api_version]

	      if @@hide_documentation_path
	        routes.reject!{ |route, value| "/#{route}/".index(parse_path(@@mount_path, nil) << '/') == 0 }
	      end

	      routes_array = routes.keys.map do |local_route|
	          { :path => "#{parse_path(route.route_path.gsub('(.:format)', ''), route.route_version, @@hide_format)
                          }/#{local_route}#{@@hide_format ? '' : '.{format}'}" }
	      end
	      {
	        apiVersion: requested_api_version,
	        swaggerVersion: "1.1",
	        basePath: parse_base_path(@@base_path, request),
	        operations:[],
	        apis: routes_array
	      }
	    end
	end

  def register_resource_handler
    desc 'Swagger compatible API description for specific API',
          :params =>{
            "name" => {
              :desc => "Resource name of mounted API",
              :type => "string",
              :required => true },
          }
    get "#{@@mount_path}/:name" do
      header['Access-Control-Allow-Origin'] = '*'
      header['Access-Control-Request-Method'] = '*'

      #routes = @@target_class::combined_routes[@@api_version][params[:name]]
        
      requested_api_version = params[:route_info].route_version
      requested_resource = params[:name]
      p "#--- Requested API Version: #{requested_api_version}"
     
      routes = @@target_class::combined_routes[requested_api_version][requested_resource]

      routes_array = routes.map do |route|
        notes = route.route_notes && @@markdown ? Kramdown::Document.new(strip_heredoc(route.route_notes)).to_html : route.route_notes
        http_codes = parse_http_codes(route.route_http_codes)
        operations = {
            :notes => notes,
            :summary => route.route_description || '',
            :nickname   => route.route_method + route.route_path.gsub(/[\/:\(\)\.]/,'-'),
            :httpMethod => route.route_method,
            :parameters => parse_header_params(route.route_headers) +
              parse_params(route.route_params, route.route_path, route.route_method)
        }
        operations.merge!({:errorResponses => http_codes}) unless http_codes.empty?
        {
          :path => parse_path(route.route_path, requested_api_version, @@hide_format),
          :operations => [operations]
        }
      end

      {
        apiVersion: @@api_version,
        swaggerVersion: "1.1",
        basePath: parse_base_path(@@base_path, request),
        resourcePath: "",
        apis: routes_array
      }
    end
  end
end
