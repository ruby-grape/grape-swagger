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

    def content_types_for(target_class)
      content_types = (target_class.content_types || {}).values

      if content_types.empty?
        formats       = [target_class.format, target_class.default_format].compact.uniq
        formats       = Grape::Formatter::Base.formatters({}).keys if formats.empty?
        content_types = Grape::ContentTypes::CONTENT_TYPES.select { |content_type, _mime_type| formats.include? content_type }.values
      end

      content_types.uniq
    end

    def setup(options)
      options = defaults.merge(options)

      # options could be set on #add_swagger_documentation call,
      # for available options see #defaults
      target_class     = options[:target_class]
      api_version      = options[:api_version]
      authorizations   = options[:authorizations]
      root_base_path   = options[:root_base_path]
      extra_info       = options[:info]
      api_doc          = options[:api_documentation].dup
      specific_api_doc = options[:specific_api_documentation].dup

      set_class_variables_from(options)

      [:format, :default_format, :default_error_formatter].each do |method|
        send(method, options[:format])
      end if options[:format]

      @@documentation_class = self

      desc api_doc.delete(:desc), api_doc
      get @@mount_path do
        header['Access-Control-Allow-Origin']   = '*'
        header['Access-Control-Request-Method'] = '*'

        output = swagger_object(
          info_object(extra_info.merge({version: api_version})),
          @@documentation_class.content_types_for(target_class),
        )

        output[:authorizations] = authorizations unless authorizations.nil? || authorizations.empty?
        output[:host]           = request.env['HTTP_HOST'] || options[:host]
        output[:basePath]       = request.env['SCRIPT_NAME'] || options[:base_path]
        paths, definitions      = path_and_definition_objects(target_class, options)
        output[:paths]          = paths if paths
        output[:definitions]    = definitions if definitions

        output
      end
    end

    def defaults
      {
        api_version: 'v1.0',
        target_class: nil,
        mount_path: '/swagger_doc',
        host: nil,
        base_path: nil,
        markdown: nil,
        hide_documentation_path: true,
        hide_format: true,
        format: nil,
        models: [],
        info: {},
        authorizations: nil,
        root_base_path: true,
        api_documentation: { desc: 'Swagger compatible API description' },
        specific_api_documentation: { desc: 'Swagger compatible API description for specific API' }
      }
    end

    def set_class_variables_from(options)
      @@mount_path              = options[:mount_path]
      @@class_name              = options[:class_name] || options[:mount_path].delete('/')
      @@markdown                = options[:markdown] ? GrapeSwagger::Markdown.new(options[:markdown]) : nil
      @@hide_format             = true
      @@models                  = options[:models] || []
      @@hide_documentation_path = options[:hide_documentation_path]
    end

  end
end
