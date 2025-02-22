# frozen_string_literal: true

require_relative 'request_param_parsers/headers'
require_relative 'request_param_parsers/route'
require_relative 'request_param_parsers/body'

module GrapeSwagger
  class RequestParamParserRegistry
    DEFAULT_PARSERS = [
      GrapeSwagger::RequestParamParsers::Headers,
      GrapeSwagger::RequestParamParsers::Route,
      GrapeSwagger::RequestParamParsers::Body
    ].freeze

    include Enumerable

    def initialize
      @parsers = DEFAULT_PARSERS.dup
    end

    def register(klass)
      remove_parser(klass)
      @parsers << klass
    end

    def insert_before(before_klass, klass)
      remove_parser(klass)
      insert_at = @parsers.index(before_klass) || @parsers.size
      @parsers.insert(insert_at, klass)
    end

    def insert_after(after_klass, klass)
      remove_parser(klass)
      insert_at = @parsers.index(after_klass)
      @parsers.insert(insert_at ? insert_at + 1 : @parsers.size, klass)
    end

    def each(&)
      @parsers.each(&)
    end

    private

    def remove_parser(klass)
      @parsers.reject! { |k| k == klass }
    end
  end
end
