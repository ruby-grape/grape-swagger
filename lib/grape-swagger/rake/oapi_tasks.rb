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
          urls_for(api_class).each do |url|
            make_request(url)

            save_to_file? ? File.write(file(url), @oapi) : $stdout.print(@oapi)
          end

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

          urls_for(api_class).each do |url|
            @output = system "swagger-cli validate #{file(url)}"

            FileUtils.rm(
              file(url)
            )
          end

          $stdout.puts 'install swagger-cli with `npm install swagger-cli -g`' if @output.nil?
          # :nocov:
        end
      end

      # helper methods
      #
      # rubocop:disable Style/StringConcatenation
      def make_request(url)
        get url

        @oapi = JSON.pretty_generate(
          JSON.parse(last_response.body, symolize_names: true)
        ) + "\n"
      end
      # rubocop:enable Style/StringConcatenation

      def urls_for(api_class)
        api_class.routes
                 .map(&:path)
                 .select { |e| e.include?('doc') }
                 .reject { |e| e.include?(':name') }
                 .map { |e| format_path(e) }
                 .map { |e| [e, ENV.fetch('resource', nil)].join('/').chomp('/') }
      end

      def format_path(path)
        oapi_route = api_class.routes.select { |e| e.path == path }.first
        path = path.sub(/\(\.\w+\)$/, '').sub(/\(\.:\w+\)$/, '')
        path.sub(':version', oapi_route.version.to_s)
      end

      def save_to_file?
        ENV['store'].present? && !error?
      end

      def error?
        JSON.parse(@oapi).keys.first == 'error'
      end

      def file(url)
        api_version = url.split('/').last

        name = if ENV['store'] == 'true' || ENV['store'].blank?
                 "swagger_doc_#{api_version}.json"
               else
                 ENV['store'].sub('.json', "_#{api_version}.json")
               end

        File.join(Dir.getwd, name)
      end

      def app
        api_class.new
      end
    end
  end
end
