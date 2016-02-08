module GrapeSwagger
  module DocMethods
    class Produces
      class << self
        def call(*args)
          return ['application/json'] unless args.flatten.present?
          args.flatten.map { |x| Grape::ContentTypes::CONTENT_TYPES[x] || x }.uniq
        end
      end
    end
  end
end
