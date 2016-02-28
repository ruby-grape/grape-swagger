module GrapeSwagger
  module DocMethods
    def name
      @@class_name
    end

    def hide_documentation_path
      @@hide_documentation_path
    end

    def mount_path
      @@mount_path
    end

    def setup(options)
      options = defaults.merge(options)

      # options could be set on #add_swagger_documentation call,
      # for available options see #defaults
      target_class     = options[:target_class]
      api_version      = options[:api_version]
      extra_info       = options[:info]
      api_doc          = options[:api_documentation].dup
      specific_api_doc = options[:specific_api_documentation].dup

      class_variables_from(options)

      [:format, :default_format, :default_error_formatter].each do |method|
        send(method, options[:format])
      end if options[:format]
      # getting of the whole swagger2.0 spec file
      desc api_doc.delete(:desc), api_doc
      get mount_path do
        header['Access-Control-Allow-Origin']   = '*'
        header['Access-Control-Request-Method'] = '*'

        output = swagger_object(
          info_object(extra_info.merge(version: api_version)),
          target_class,
          request,
          options
        )

        target_routes        = target_class.combined_namespace_routes
        paths, definitions   = path_and_definition_objects(target_routes, options)
        output[:paths]       = paths unless paths.blank?
        output[:definitions] = definitions unless definitions.blank?

        output
      end

      # getting of a specific/named route of the swagger2.0 spec file
      desc specific_api_doc.delete(:desc), { params:
        specific_api_doc.delete(:params) || {} }.merge(specific_api_doc)
      params do
        requires :name, type: String, desc: 'Resource name of mounted API'
        optional :locale, type: Symbol, desc: 'Locale of API documentation'
      end
      get "#{mount_path}/:name" do
        I18n.locale = params[:locale] || I18n.default_locale

        combined_routes = target_class.combined_namespace_routes[params[:name]]
        error!({ error: 'named resource not exist' }, 400) if combined_routes.nil?

        output = swagger_object(
          info_object(extra_info.merge(version: api_version)),
          target_class,
          request,
          options
        )

        target_routes        = { params[:name] => combined_routes }
        paths, definitions   = path_and_definition_objects(target_routes, options)
        output[:paths]       = paths unless paths.blank?
        output[:definitions] = definitions unless definitions.blank?

        output
      end
    end

    def defaults
      {
        api_version: 'v1',
        target_class: nil,
        mount_path: '/swagger_doc',
        host: nil,
        base_path: nil,
        markdown: false,
        hide_documentation_path: true,
        format: :json,
        models: [],
        info: {},
        scheme: %w( http https ),
        authorizations: nil,
        root_base_path: true,
        api_documentation: { desc: 'Swagger compatible API description' },
        specific_api_documentation: { desc: 'Swagger compatible API description for specific API' }
      }
    end

    def class_variables_from(options)
      @@mount_path              = options[:mount_path]
      @@class_name              = options[:class_name] || options[:mount_path].delete('/')
      @@hide_documentation_path = options[:hide_documentation_path]
    end
  end
end
