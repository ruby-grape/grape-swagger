# frozen_string_literal: true

require 'rake'
require 'rake/tasklib'
require 'rack/test'

module GrapeSwagger
  module Rake
    class OapiTasks < ::Rake::TaskLib
      include Rack::Test::Methods

      attr_reader :oapi

      def initialize(api_class)
        super()

        if api_class.is_a? String
          @api_class_name = api_class
        else
          @api_class = api_class
        end

        define_tasks
      end

      private

      def api_class
        @api_class ||= @api_class_name.constantize
      end

      def define_tasks
        namespace :oapi do
          fetch
          validate
        end
      end

      # tasks
      #
      # get swagger/OpenAPI documentation
      def fetch
        desc 'generates OpenApi documentation …
          params (usage: key=value):
          store    – save as JSON file, default: false            (optional)
          resource - if given only for that it would be generated (optional)'
        task fetch: :environment do
          # :nocov:
          make_request

          save_to_file? ? File.write(file, @oapi) : $stdout.print(@oapi)
          # :nocov:
        end
      end

      # validates swagger/OpenAPI documentation
      def validate
        desc 'validates the generated OpenApi file …
          params (usage: key=value):
          resource - if given only for that it would be generated (optional)'
        task validate: :environment do
          # :nocov:
          ENV['store'] = 'true'
          ::Rake::Task['oapi:fetch'].invoke
          exit if error?

          output = system "swagger validate #{file}"

          $stdout.puts 'install swagger-cli with `npm install swagger-cli -g`' if output.nil?
          FileUtils.rm(file)
          # :nocov:
        end
      end

      # helper methods
      #
      def make_request
        get url_for

        @oapi = JSON.pretty_generate(
          JSON.parse(
            last_response.body, symolize_names: true
          )
        ) + "\n"
      end

      def url_for
        oapi_route = api_class.routes[-2]
        path = oapi_route.path.sub(/\(\.\w+\)$/, '').sub(/\(\.:\w+\)$/, '')
        path.sub!(':version', oapi_route.version.to_s)

        [path, ENV['resource']].join('/').chomp('/')
      end

      def save_to_file?
        ENV['store'].present? && !error?
      end

      def error?
        JSON.parse(@oapi).keys.first == 'error'
      end

      def file
        name = ENV['store'] == 'true' || ENV['store'].blank? ? 'swagger_doc.json' : ENV['store']
        File.join(Dir.getwd, name)
      end

      def app
        api_class.new
      end
    end
  end
end
