require 'spec_helper'

describe 'Array Entity' do
  before :all do
    class Something < Grape::Entity
      expose :text, documentation: { type: 'string', desc: 'Content of something.' }
    end
  end

  def app
    Class.new(Grape::API) do
      format :json

      desc 'This returns something or an error',
           is_array: true,
           entity: Something
      post :action do
      end

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc/action'
    JSON.parse(last_response.body)
  end

  it 'reads param type correctly' do
    expect(subject['models'].keys).to include 'Something'
    expect(subject['apis'][0]['operations'][0]['type']).to eq('array')
    expect(subject['apis'][0]['operations'][0]['items']).to eq('$ref' => 'Something')
  end
end
