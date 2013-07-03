=begin
  GrapeSwaggerHandlers module includes functions that
  register handlers for GrapeSwagger doc views.
=end

module GrapeSwaggerHandlers
	def register_handlers(options)
    @@target_class = options[:target_class]

    @@mount_path = options[:mount_path]
    @@class_name = options[:class_name] || options[:mount_path].gsub('/','')

		register_root_handler
    register_resource_handler
	end
	def register_root_handler()
	    desc 'Swagger compatible API description'
	    get @@mount_path do
	      header['Access-Control-Allow-Origin'] = '*'
	      header['Access-Control-Request-Method'] = '*'
	        
        requested_api_version = get_requested_version(params)
       
        routes = @@target_class::combined_routes[requested_api_version]
        doc_options = @@target_class::documentation_options[requested_api_version]

	      if doc_options[:hide_documentation_path]
          parsed_path =  parse_path(doc_options[:mount_path], requested_api_version, nil) 
	        routes.reject!{ |route, value| "/#{route}/".index(parsed_path << '/') == 0 }
	      end

	      routes_array = routes.keys.map do |local_route|
          parsed_path = parse_path(route.route_path.gsub('(.:format)', ''), route.route_version, doc_options[:hide_format])
	        {:path => "#{parsed_path}/#{local_route}#{doc_options[:hide_format] ? '' : '.{format}'}" }
	      end

	      {
	        apiVersion: requested_api_version,
	        swaggerVersion: "1.1",
	        basePath: parse_base_path(doc_options[:base_path], request),
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
              :required => true 
            }
          }
    get "#{@@mount_path}/:name" do
      header['Access-Control-Allow-Origin'] = '*'
      header['Access-Control-Request-Method'] = '*'
      
      requested_api_version = get_requested_version(params)
      requested_resource = params[:name]
     
      routes = @@target_class::combined_routes[requested_api_version][requested_resource]
      doc_options = @@target_class::documentation_options[requested_api_version]

      routes_array = routes.map do |route|
        notes = parse_notes(route.route_notes, doc_options)
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
          :path => parse_path(route.route_path, requested_api_version, doc_options[:hide_format]),
          :operations => [operations]
        }
      end

      {
        apiVersion: requested_api_version,
        swaggerVersion: "1.1",
        basePath: parse_base_path(doc_options[:base_path], request),
        resourcePath: "",
        apis: routes_array
      }
    end
  end
end
