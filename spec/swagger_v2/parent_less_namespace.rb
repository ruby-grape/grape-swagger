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
    subject do
      get '/api/swagger_doc.json'
      JSON.parse(last_response.body)
    end

    context 'not raises error' do
      specify do
        expect(subject['tags']).to eql(
                                     [
                                       { 'name' => 'queues', 'description' => 'Operations about queues' }
                                     ]
                                   )

        expect(subject['paths']['/api/{animal}/{breed}/queues/{queue_id}/reservations']['get']['operationId']).
          to eql('getApiAnimalBreedQueuesQueueIdReservations')
      end
    end

    context 'raises error' do
      # If /lib/grape-swagger.rb:103 doesn't exist, it's raises
      # NoMethodError:
      #  undefined method `reject' for nil:NilClass
    end
  end
end

