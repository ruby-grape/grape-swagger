# backwards compatibility for Grape < 0.16.0
module Grape
  class Route
    [:path, :prefix, :entity, :description, :settings, :params, :headers, :http_codes, :version]
      .each do |m|
      define_method m do
        send "route_#{m}"
      end
    end

    def request_method
      route_method
    end

    attr_reader :options
  end
end if defined?(Grape::VERSION) && Gem::Version.new(::Grape::VERSION) < Gem::Version.new('0.16.0')
