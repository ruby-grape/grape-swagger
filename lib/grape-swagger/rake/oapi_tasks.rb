require 'rake'
require 'rake/tasklib'
require 'rack/test'

module GrapeSwagger
  module Rake
    class OapiTasks < ::Rake::TaskLib
      include Rack::Test::Methods

      attr_reader :oapi
      attr_reader :api_class

      def initialize(api_class)
        super()
        @api_class = api_class
        define_tasks
      end

      private

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
        desc 'generates OpenApi documentation (`store=true`, stores to FS)'
        task fetch: :environment do
          make_request
          ENV['store'] ? File.write(file, @oapi) : print(@oapi)
        end
      end

      # validates swagger/OpenAPI documentation
      def validate
        desc 'validates the generated OpenApi file'
        task validate: :environment do
          ENV['store'] = 'true'
          ::Rake::Task['oapi:fetch'].invoke

          output = system "swagger validate #{file}"

          $stdout.puts 'install swagger-cli with `npm install swagger-cli -g`' if output.nil?
          FileUtils.rm(file)
        end
      end

      # helper methods
      #
      def make_request
        get url_for
        last_response
        @oapi = JSON.pretty_generate(
          JSON.parse(
            last_response.body, symolize_names: true
          )
        )
      end

      def url_for
        oapi_route = api_class.routes[-2]
        url = '/swagger_doc'
        url = "/#{oapi_route.version}#{url}" if oapi_route.version
        url = "/#{oapi_route.prefix}#{url}" if oapi_route.prefix
        url
      end

      def file
        File.join(Dir.getwd, 'swagger_doc.json')
      end

      def app
        api_class.new
      end
    end
  end
end
