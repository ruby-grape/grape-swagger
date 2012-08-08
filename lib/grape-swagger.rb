require 'kramdown'

module Grape
  class API
    class << self
      attr_reader :combined_routes

      alias original_mount mount

      def mount(mounts)
        original_mount mounts
        @combined_routes ||= {}
        mounts::routes.each do |route|
          resource = route.route_path.match('\/(.*?)[\.\/\(]').captures.first || '/'
          @combined_routes[resource.downcase] ||= []
          @combined_routes[resource.downcase] << route
        end
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
              :markdown => false
            }
            options = defaults.merge(options)

            @@target_class = options[:target_class]
            @@mount_path = options[:mount_path]
            @@class_name = options[:class_name] || options[:mount_path].gsub('/','')
            @@markdown = options[:markdown]
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
                "name" => { :desc => "Resource name of mounted API", :type => "string", :required => true },
              }
            get "#{@@mount_path}/:name" do
              header['Access-Control-Allow-Origin'] = '*'
              header['Access-Control-Request-Method'] = '*'
              routes = @@target_class::combined_routes[params[:name]]
              routes_array = routes.map do |route|
                notes = route.route_notes && @@markdown ? Kramdown::Document.new(route.route_notes.strip_heredoc).to_html : route.route_notes
                {
                  :path => parse_path(route.route_path),
                  :operations => [{
                    :notes => notes,
                    :summary => route.route_description || '',
                    :nickname   => route.route_method + route.route_path.gsub(/[\/:\(\)\.]/,'-'),
                    :httpMethod => route.route_method,
                    :parameters => parse_params(route.route_params, route.route_path, route.route_method)
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
            def parse_params(params, path, method)
              params.map do |param, value|
                value[:type] = 'file' if value.is_a?(Hash) && value[:type] == 'Rack::Multipart::UploadedFile'

                dataType = value.is_a?(Hash) ? value[:type]||'String' : 'String'
                description = value.is_a?(Hash) ? value[:desc] : ''
                required = value.is_a?(Hash) ? !!value[:required] : false
                paramType = path.match(":#{param}") ? 'path' : (method == 'POST') ? 'body' : 'query'
                {
                  paramType: paramType,
                  name: param,
                  description: description,
                  dataType: dataType,
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

class Object
  ##
  #   @person ? @person.name : nil
  # vs
  #   @person.try(:name)
  # 
  # File activesupport/lib/active_support/core_ext/object/try.rb#L32
   def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      __send__(*a, &b)
    end
  end
end

class String
  # strip_heredoc from rails
  # File activesupport/lib/active_support/core_ext/string/strip.rb, line 22
  def strip_heredoc
    indent = scan(/^[ \t]*(?=\S)/).min.try(:size) || 0
    gsub(/^[ \t]{#{indent}}/, '')
  end
end
