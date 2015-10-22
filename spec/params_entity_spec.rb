require 'spec_helper'

describe 'Array Params' do
  before do
    module Entities
      class Item < Grape::Entity
        expose :content, documentation: { type: String }
      end

      class Set < Grape::Entity
        expose :items, using: Entities::Item, documentation: { type: Set, is_array: true }
      end
    end
  end

  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :a_array, type: Entities::Set
      end
      post :splines do
      end

      params do
        optional :raw_array, type: Array
      end
      get :raw_array_splines do
      end

      params do
        optional :raw_array, type: Array[Integer]
      end
      get :raw_array_integers do
      end

      add_swagger_documentation
    end
  end

  before do
    get '/swagger_doc/splines'
  end

  let(:response) { JSON.parse(last_response.body) }
  specify do
  end
end
