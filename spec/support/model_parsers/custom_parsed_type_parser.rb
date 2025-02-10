# frozen_string_literal: true

CustomParsedType = Class.new

class CustomParsedTypeParser
  attr_reader :model, :endpoint

  def initialize(model, endpoint)
    @model = model
    @endpoint = endpoint
  end

  def call
    {
      type: "object",
      properties: {
        custom: {
          type: 'boolean',
          description: "it's a custom type",
          default: true,
        }
      },
      required: [],
    }
  end
end

GrapeSwagger.model_parsers.register(CustomParsedTypeParser, CustomParsedType)
