# frozen_string_literal: true

module GrapeSwagger
  module ApiModel
    # API metadata information.
    class Info
      attr_accessor :title, :description, :terms_of_service, :version,
                    :contact_name, :contact_email, :contact_url,
                    :license_name, :license_url, :license_identifier,
                    :extensions

      def initialize(attrs = {})
        attrs.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        @extensions ||= {}
      end

      def contact
        return nil unless contact_name || contact_email || contact_url

        {
          name: contact_name,
          email: contact_email,
          url: contact_url
        }.compact
      end

      def license
        return nil unless license_name || license_url || license_identifier

        {
          name: license_name,
          url: license_url,
          identifier: license_identifier
        }.compact
      end

      def to_h
        hash = {
          title: title || 'API title',
          version: version || '1.0'
        }
        hash[:description] = description if description
        hash[:termsOfService] = terms_of_service if terms_of_service
        hash[:contact] = contact if contact
        hash[:license] = license if license
        extensions.each { |k, v| hash[k] = v } if extensions.any?
        hash
      end
    end
  end
end
