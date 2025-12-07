# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Builder
      # Builds OpenAPI Info object from configuration options
      module InfoBuilder
        private

        def build_info
          info_options = options[:info] || {}
          @spec.info = OpenAPI::Info.new(
            title: info_options[:title] || 'API title',
            description: info_options[:description],
            terms_of_service: info_options[:terms_of_service_url],
            version: options[:doc_version] || info_options[:version] || '1.0',
            contact_name: info_options[:contact_name],
            contact_email: info_options[:contact_email],
            contact_url: info_options[:contact_url]
          )

          build_license(info_options)
          copy_info_extensions(info_options)
        end

        def build_license(info_options)
          license = info_options[:license]
          return unless license

          if license.is_a?(Hash)
            @spec.info.license_name = license[:name]
            @spec.info.license_url = license[:url] || info_options[:license_url]
            @spec.info.license_identifier = license[:identifier]
          else
            @spec.info.license_name = license
            @spec.info.license_url = info_options[:license_url]
          end
        end

        def copy_info_extensions(info_options)
          info_options.each do |key, value|
            @spec.info.extensions[key] = value if key.to_s.start_with?('x-')
          end
        end
      end
    end
  end
end
