module GrapeSwagger
  class Markdown
    class KramdownAdapter
      attr_reader :options

      ###
      # Initializes the kramdown adapter with options.
      # See kramdown documentation what options can be passed.
      # Default it uses Github flavoured markup as input and won't use coderay as converter for syntax highlighting.
      # config: an hash of configuration options to be passed to the kramdown.
      # usage:
      # Add the kramdown gem to your gemfile or run:
      # $ (sudo) gem install kramdown
      #
      # Then pass a new instance of GrapeSwagger::Markdown::KramdownAdapter as markdown option.
      ###
      def initialize(config = {})
        require 'kramdown'
        defaults = {
          input: 'GFM',
          enable_coderay: false
        }
        @options = defaults.merge(config)
      rescue LoadError
        raise GrapeSwagger::Errors::MarkdownDependencyMissingError, 'kramdown'
      end

      ###
      # marks down the given text to html format.
      # text: The text to be formatted.
      ###
      def markdown(text)
        Kramdown::Document.new(text, @options).to_html
      end
    end
  end
end
