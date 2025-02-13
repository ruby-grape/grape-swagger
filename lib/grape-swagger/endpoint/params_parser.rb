# frozen_string_literal: true

module GrapeSwagger
  module Endpoint
    class ParamsParser
      attr_reader :route, :params, :settings, :endpoint

      def self.parse(route, params, settings, endpoint)
        new(route, params, settings, endpoint).parse
      end

      def initialize(_route, params, settings, endpoint)
        @params = params
        @settings = settings
        @endpoint = endpoint
      end

      def parse
        public_params.each_with_object({}) do |(name, options), memo|
          name = name.to_s
          param_type = options[:type]
          param_type = param_type.to_s unless param_type.nil?

          if param_type_is_array?(param_type)
            options[:is_array] = true
            name += '[]' if array_use_braces?
          end

          memo[name] = options
        end
      end
      alias parse_request_params parse

      private

      def array_use_braces?
        @array_use_braces ||= settings[:array_use_braces] && !includes_body_param?
      end

      def param_type_is_array?(param_type)
        return false unless param_type
        return true if param_type == 'Array'

        param_types = param_type.match(/\[(.*)\]$/)
        return false unless param_types

        param_types = param_types[0].split(',') if param_types
        param_types.size == 1
      end

      def public_params
        params.select { |_key, param| public_parameter?(param) }
      end

      def public_parameter?(param_options)
        return true unless param_options.key?(:documentation) && !param_options[:required]

        param_hidden = param_options[:documentation].fetch(:hidden, false)
        if param_hidden.is_a?(Proc)
          param_hidden = if settings[:token_owner]
                           param_hidden.call(endpoint.send(settings[:token_owner].to_sym))
                         else
                           param_hidden.call
                         end
        end
        !param_hidden
      end

      def includes_body_param?
        params.any? do |_, options|
          options.dig(:documentation, :param_type) == 'body' || options.dig(:documentation, :in) == 'body'
        end
      end
    end
  end
end
