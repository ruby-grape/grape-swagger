# frozen_string_literal: true

module RouteHelper
  def self.build(method:, pattern:, options:, origin: nil)
    if GrapeVersion.satisfy?('>= 2.3.0')
      Grape::Router::Route.new(method, origin || pattern, pattern, options)
    else
      Grape::Router::Route.new(method, pattern, **options)
    end
  end
end
