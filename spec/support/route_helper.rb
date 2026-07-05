# frozen_string_literal: true

module RouteHelper
  def self.build(method:, pattern:, options:, origin: nil)
    if GrapeVersion.satisfy?('>= 4.0.0')
      pattern_obj = Grape::Router::Pattern.new(
        origin: origin || pattern,
        suffix: nil,
        anchor: options.fetch(:anchor, true),
        params: options.fetch(:params, {}),
        version: nil,
        requirements: options.fetch(:requirements, {})
      )
      Grape::Router::Route.new(nil, method, pattern_obj, options, forward_match: options.fetch(:forward_match, false))
    elsif GrapeVersion.satisfy?('>= 3.1.0')
      pattern_obj = Grape::Router::Pattern.new(
        origin: origin || pattern,
        suffix: nil,
        anchor: options.fetch(:anchor, true),
        params: options.fetch(:params, {}),
        format: nil,
        version: nil,
        requirements: options.fetch(:requirements, {})
      )
      Grape::Router::Route.new(nil, method, pattern_obj, options)
    elsif GrapeVersion.satisfy?('>= 2.3.0')
      Grape::Router::Route.new(method, origin || pattern, pattern, options)
    else
      Grape::Router::Route.new(method, pattern, **options)
    end
  end
end
