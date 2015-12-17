RSpec.shared_context "the api entities" do
  before :all do
    module TheApi
      module Entities
        class ApiError < Grape::Entity
          expose :code, documentation: { type: Integer }
          expose :message, documentation: { type: String }
        end

        class ResponseItem < Grape::Entity
          expose :id, documentation: { type: Integer }
          expose :name, documentation: { type: String }
        end

        class UseResponse < Grape::Entity
          expose :description, documentation: { type: String }
          expose :items, as: '$responses', using: Entities::ResponseItem, documentation: { is_array: true }
        end
      end
    end
  end


end
