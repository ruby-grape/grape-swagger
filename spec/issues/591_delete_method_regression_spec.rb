require 'spec_helper'

describe '#591 delete method regression' do
  include_context "#{MODEL_PARSER} swagger example"

  let(:app) do
    class Foo < Grape::Entity
      expose :something
    end

    Class.new(Grape::API) do
      namespace :issue_591 do
        desc 'delete with model',
             is_array: false,
             success: { code: 200, model: Foo, message: 'deleted' }
        delete '/deleteme' do
          present({ something: 'bar' }, with: Foo)
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  specify do
    expect(subject).to_not be_nil
  end
end
