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
      @parsers << klass
    end

    def insert_before(before_klass, klass)
      insert_at = @parsers.index(before_klass)
      insert_at = @parsers.length - 1 if insert_at.nil?
      @parsers.insert(insert_at, klass)
    end

    def insert_after(after_klass, klass)
      insert_at = @parsers.index(after_klass)
      insert_at = @parsers.length - 1 if insert_at.nil?
      @parsers.insert(insert_at + 1, klass)
    end

    def each
      @parsers.each do |klass|
        yield klass
      end
    end
  end
end
