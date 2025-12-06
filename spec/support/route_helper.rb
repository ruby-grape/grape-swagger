# frozen_string_literal: true

module RouteHelper
  def self.build(method:, pattern:, options:, origin: nil)
    if GrapeVersion.satisfy?('>= 3.1.0')
      # Grape 3.1+ has new Route constructor: (endpoint, method, pattern_object, options)
      pattern_obj = Grape::Router::Pattern.new(
        origin: origin || pattern,
        suffix: '',
        anchor: options.fetch(:anchor, true),
        params: options[:params] || {},
        format: nil,
        version: nil,
        requirements: options[:requirements] || {}
      )
      Grape::Router::Route.new(nil, method, pattern_obj, options)
    elsif GrapeVersion.satisfy?('>= 2.3.0')
      Grape::Router::Route.new(method, origin || pattern, pattern, options)
    else
      Grape::Router::Route.new(method, pattern, **options)
    end
  end
end
