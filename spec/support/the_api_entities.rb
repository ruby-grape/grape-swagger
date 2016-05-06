RSpec.shared_context 'the api entities' do
  before :all do
    module TheApi
      module Entities
        class ApiError < Grape::Entity
          expose :code, documentation: { type: Integer }
          expose :message, documentation: { type: String }
        end

        class SecondApiError < Grape::Entity
          expose :code, documentation: { type: Integer }
          expose :severity, documentation: { type: String }
          expose :message, documentation: { type: String }
        end

        class ResponseItem < Grape::Entity
          expose :id, documentation: { type: Integer }
          expose :name, documentation: { type: String }
        end

        class OtherItem < Grape::Entity
          expose :key, documentation: { type: Integer }
          expose :symbol, documentation: { type: String }
        end

        class UseResponse < Grape::Entity
          expose :description, documentation: { type: String }
          expose :items, as: '$responses', using: Entities::ResponseItem, documentation: { is_array: true }
        end

        class UseItemResponseAsType < Grape::Entity
          expose :description, documentation: { type: String }
          expose :responses, documentation: { type: Entities::ResponseItem, is_array: false }
        end

        class UseAddress < Grape::Entity
          expose :street, documentation: { type: String, desc: 'street' }
          expose :postcode, documentation: { type: String, desc: 'postcode' }
          expose :city, documentation: { type: String, desc: 'city' }
          expose :country, documentation: { type: String, desc: 'country' }
        end

        class UseNestedWithAddress < Grape::Entity
          expose :name, documentation: { type: String }
          expose :address, using: Entities::UseAddress
        end
      end
    end
  end
end
