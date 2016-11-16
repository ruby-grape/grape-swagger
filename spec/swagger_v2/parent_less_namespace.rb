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

    context 'not raises error' do
      specify do
        expect(subject['tags']).to eql([{ 'name' => 'queues', 'description' => 'Operations about queues' }])
        expect(subject['paths']['/api/{animal}/{breed}/queues/{queue_id}/reservations']['get']['operationId'])
          .to eql('getApiAnimalBreedQueuesQueueIdReservations')
      end
    end

    context 'raises error' do
      specify do
        allow_any_instance_of(ParentLessApi)
          .to receive(:extract_parent_route).with(route_name).and_return(':animal') # BUT IT'S NOT STUBBING, CAUSE IT'S A PRIVATE METHODS
        expect { subject }.to raise_error NoMethodError
      end
    end

    context 'ParentLessApi.extract_parent_route' do
      specify do
        expect(ParentLessApi.send(:extract_parent_route, route_name)).to eq('queues')
      end
    end
  end
end
