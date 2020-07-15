# frozen_string_literal: true

class EmptyClass
end

module GrapeSwagger
  class EmptyModelParser
    attr_reader :model, :endpoint

    def initialize(model, endpoint)
      @model = model
      @endpoint = endpoint
    end

    def call
      {}
    end
  end
end

GrapeSwagger.model_parsers.register(GrapeSwagger::EmptyModelParser, EmptyClass)
