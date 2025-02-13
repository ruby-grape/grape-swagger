# frozen_string_literal: true

module GrapeSwagger
  module Endpoint
    class HeadersParser
      class << self
        def parse(route)
          route.headers.to_a.map do |route_header|
            route_header.tap do |header|
              hash = header[1]
              description = hash.delete('description')
              hash[:documentation] = { desc: description, in: 'header' }
              hash[:type] = hash['type'].titleize if hash['type']
            end
          end
        end
      end
    end
  end
end
