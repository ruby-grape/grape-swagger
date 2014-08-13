module GrapeSwagger
  module Errors
    class MarkdownDependencyMissingError < StandardError
      def initialize(missing_gem)
        super("Missing required dependency: #{missing_gem}")
      end
    end
  end
end
