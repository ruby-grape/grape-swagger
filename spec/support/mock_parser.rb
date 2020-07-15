# frozen_string_literal: true

module GrapeSwagger
  class MockParser
    attr_reader :model, :endpoint

    def initialize(model, endpoint)
      @model = model
      @endpoint = endpoint
    end

    def call
      {
        mock_data: {
          type: :string,
          description: "it's a mock"
        }
      }
    end
  end
end

GrapeSwagger.model_parsers.register(GrapeSwagger::MockParser, OpenStruct)
