# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    class ProducesConsumes
      class << self
        def call(*args)
          return ['application/json'] unless args.flatten.present?

          args.flatten.map { |x| GrapeSwagger::CONTENT_TYPE_DEFAULTS[x] || x }.uniq
        end
      end
    end
  end
end
