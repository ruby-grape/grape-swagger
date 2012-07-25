module Grape
  class API
    class << self
      attr_reader :combined_routes

      alias original_mount mount

      def mount(mounts)
        original_mount mounts
        @combined_routes ||= {}
        @combined_routes[mounts.name.split('::').last.downcase] = mounts::routes
      end

      def add_swagger_documentation(options={})
        documentation_class = create_documentation_class

        documentation_class.setup({:target_class => self}.merge(options))
        mount(documentation_class)
      end

      private

      def create_documentation_class

        Class.new(Grape::API) do
          class << self
            def name
              @@class_name
            end
          end

          def self.setup(options)
            defaults = {
              :target_class => nil,
              :mount_path => '/swagger_doc',
              :base_path => nil,
              :api_version => '0.1',
            }
            options = defaults.merge(options)

            @@target_class = options[:target_class]
            @@mount_path = options[:mount_path]
            @@class_name = options[:class_name] || options[:mount_path].gsub('/','')
            api_version = options[:api_version]
            base_path = options[:base_path]

            desc 'Swagger compatible API description'
            get @@mount_path do
              header['Access-Control-Allow-Origin'] = '*'
              header['Access-Control-Request-Method'] = '*'
              routes = @@target_class::combined_routes

              routes_array = routes.keys.map do |route|
                  { :path => "#{@@mount_path}/#{route}.{format}" }
              end
              {
                apiVersion: api_version,
                swaggerVersion: "1.1",
                basePath: base_path || "http://#{env['HTTP_HOST']}",
                operations:[],
                apis: routes_array
              }
            end

            desc 'Swagger compatible API description for specific API', :params =>
              {
                "name" => { :desc => "Class name of mounted API", :type => "string", :required => true },
              }
            get "#{@@mount_path}/:name" do
              header['Access-Control-Allow-Origin'] = '*'
              header['Access-Control-Request-Method'] = '*'
              routes = @@target_class::combined_routes[params[:name]]
              routes_array = routes.map do |route|
                {
                  :path => parse_path(route.route_path),
                  :operations => [{
                    :notes => route.route_notes,
                    :summary => route.route_description || '',
                    :nickname   => Random.rand(1000000),
                    :httpMethod => route.route_method,
                    :parameters => parse_params(route.route_params)
                  }]
                }
              end

              {
                apiVersion: api_version,
                swaggerVersion: "1.1",
                basePath: base_path || "http://#{env['HTTP_HOST']}",
                resourcePath: "",
                apis: routes_array
              }
            end
          end


          helpers do
            def parse_params(params)
              params.map do |param, value|
                dataType = value.is_a?(Hash) ? value[:type]||'String' : 'String'
                description = value.is_a?(Hash) ? value[:desc] : ''
                required = value.is_a?(Hash) ? !!value[:required] : false
                paramType = 'path'
                {
                  paramType: paramType,
                  name: param,
                  description: description,
                  dataType: "String",
                  required: required
                }
              end
            end

            def parse_path(path)
              # adapt format to swagger format
              parsed_path = path.gsub('(.:format)', '.{format}')
              # adapt params to swagger format
              parsed_path.gsub(/:([a-z]+)/, '{\1}')
            end
          end
        end
      end
    end
  end
end
