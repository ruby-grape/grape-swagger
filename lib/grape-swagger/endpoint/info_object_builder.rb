# frozen_string_literal: true

module GrapeSwagger
  module Endpoint
    class InfoObjectBuilder
      attr_reader :infos

      def self.build(infos)
        new(infos).build
      end

      def initialize(infos)
        @infos = infos
      end

      def build
        result = {
          title: infos[:title] || 'API title',
          description: infos[:description],
          termsOfService: infos[:terms_of_service_url],
          contact: contact_object,
          license: license_object,
          version: infos[:version]
        }

        GrapeSwagger::DocMethods::Extensions.add_extensions_to_info(infos, result)

        result.delete_if { |_, value| value.blank? }
      end

      private

      # sub-objects of info object
      # license
      def license_object
        {
          name: infos[:license],
          url: infos[:license_url]
        }.delete_if { |_, value| value.blank? }
      end

      # contact
      def contact_object
        {
          name: infos[:contact_name],
          email: infos[:contact_email],
          url: infos[:contact_url]
        }.delete_if { |_, value| value.blank? }
      end
    end
  end
end
