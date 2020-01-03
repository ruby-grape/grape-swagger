# frozen_string_literal: true

require 'spec_helper'

describe 'a parent less namespace' do
  include_context 'namespace example'

  before :all do
    class ParentLessApi < Grape::API
      prefix :api
      mount TheApi::ParentLessNamespaceApi
      add_swagger_documentation version: 'v1'
    end
  end

  def app
    ParentLessApi
  end

  describe 'retrieves swagger-documentation on /swagger_doc' do
    let(:route_name) { ':animal/:breed/queues/:queue_id/reservations' }
    subject do
      get '/api/swagger_doc.json'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/api/{animal}/{breed}/queues/{queue_id}/reservations']['get']['operationId'])
        .to eql('getApiAnimalBreedQueuesQueueIdReservations')
    end
  end
end
