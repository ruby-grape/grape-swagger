module GrapeSwagger
  class Markdown
    class RedcarpetAdapter
      module RenderWithoutSyntaxHighlighter
        require 'cgi'

        def block_code(code, language)
          language ||= 'text'
          "<div class=\"code_highlight\"><pre><code class=\"highlight #{language}\">#{CGI.escapeHTML(code)}</code></pre></div>"
        end
      end

      attr_reader :extension_options

      attr_reader :render_options

      ###
      # Initializes the redcarpet adapter with markup options.
      # See redcarpet documentation what options can be passed.
      # Default it uses fenced_code_blocks, autolinks and rouge as syntax highlighter.
      # To configure an highlighter add {highlighter: :value} to the extentions hash.
      # Currently supported highlighters:
      #     :rouge
      #
      # extensions: an hash of configuration options to be passed to markdown.
      # render_options: an hash of configuration options to be passed to renderer.
      #
      # usage:
      # Add the redcarpet gem to your gemfile or run:
      # $ (sudo) gem install redcarpet
      # when you want to have rouge as syntax highlighter add rouge to the gemfile or run:
      # $ (sudo) gem install rouge
      #
      # GrapeSwagger::Markdown::RedcarpetAdapter.new({highlighter: :none},{no_links: true}) # will use no syntax highlighter and won't render links.
      ###
      def initialize(options = {})
        require 'redcarpet'
        extentions_defaults = {
          fenced_code_blocks: true,
          autolink: true
        }
        render_defaults = { highlighter: :rouge }
        @extension_options = extentions_defaults.merge(options.fetch(:extensions, {}))
        @render_options = render_defaults.merge(options.fetch(:render_options, {}))
        @renderer = new_redcarpet_renderer(@render_options.delete(:highlighter)).new(@render_options)
        @markdown = Redcarpet::Markdown.new(@renderer, @extension_options)
      rescue LoadError
        raise GrapeSwagger::Errors::MarkdownDependencyMissingError, 'redcarpet'
      end

      ###
      # Marks down the given text to html format.
      ###
      def markdown(text)
        @markdown.render(text)
      end

      private

      ###
      # Creates a new redcarpet renderer based on the highlighter given.
      #
      # render_options: options passed to the renderer.
      #
      # usage:
      # new_redcarpet_renderer(:rouge)  # uses rouge as highlighter.
      # new_redcarpet_renderer          # no highlight plugin
      ###
      def new_redcarpet_renderer(syntax_highlighter = nil)
        case syntax_highlighter
        when :rouge
          begin
            Class.new(Redcarpet::Render::HTML) do
              require 'rouge'
              require 'rouge/plugins/redcarpet'
              include Rouge::Plugins::Redcarpet
            end
          rescue LoadError
            raise GrapeSwagger::Errors::MarkdownDependencyMissingError, 'rouge'
          end
        else
          Class.new(Redcarpet::Render::HTML) do
            include RenderWithoutSyntaxHighlighter
          end
        end
      end
    end
  end
end
