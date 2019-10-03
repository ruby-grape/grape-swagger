# frozen_string_literal: true

module GrapeSwagger
  module Endpoint
    class ParamsParser
      attr_reader :params, :settings

      def self.parse_request_params(params, settings)
        new(params, settings).parse_request_params
      end

      def initialize(params, settings)
        @params = params
        @settings = settings
      end

      def parse_request_params
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
        params.select { |param| public_parameter?(param) }
      end

      def public_parameter?(param)
        param_options = param.last
        return true unless param_options.key?(:documentation) && !param_options[:required]

        param_hidden = param_options[:documentation].fetch(:hidden, false)
        param_hidden = param_hidden.call if param_hidden.is_a?(Proc)
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
