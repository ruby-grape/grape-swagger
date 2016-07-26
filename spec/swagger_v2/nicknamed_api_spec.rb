require 'spec_helper'

describe 'a nicknamed mounted api' do
  before :all do
    class NicknamedMountedApi < Grape::API
      desc 'Show this endpoint', nickname: 'simple'
      get '/simple' do
        { foo: 'bar' }
      end
    end

    class NicknamedApi < Grape::API
      mount NicknamedMountedApi
      add_swagger_documentation
    end
  end

  let(:app) { NicknamedApi }

  subject do
    get '/swagger_doc.json'
    JSON.parse(last_response.body)
  end

  it "uses the nickname as the operationId" do
    expect(subject['paths']['/simple']['get']['operationId']).to eql('simple')
  end
end
