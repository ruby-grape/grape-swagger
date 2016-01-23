require 'grape-entity'

module Api
  module Entities
    class Splines < Grape::Entity
      expose :id, documentation: { type: Integer, desc: 'identity of a resource' }
      expose :x, documentation: { type: Numeric, desc: 'x-value' }
      expose :y, documentation: { type: Numeric, desc: 'y-value' }
      expose :path, documentation: { type: String, desc: 'the requested resource'}

      private

      def path
        "/#{object.class.name.demodulize.to_s.underscore}/#{object.id}"
      end
    end
  end
end
