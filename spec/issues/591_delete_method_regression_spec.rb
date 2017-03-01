require 'spec_helper'

describe '#591 delete method regression' do
  include_context "#{MODEL_PARSER} swagger example"

  let(:app) do
    class Foo < Grape::Entity
      expose :something
    end

    Class.new(Grape::API) do
      namespace :issue_591 do
        desc 'delete with model, code 200',
             is_array: false,
             success: { code: 200, model: Foo, message: 'deleted' }
        delete '/deleteme200' do
          present({ something: 'bar' }, with: Foo)
        end

        desc 'delete with model, code 204',
             is_array: false,
             success: { code: 204, model: Foo, message: 'deleted' }
        delete '/deleteme204' do
          present({ something: 'bar' }, with: Foo)
        end

        desc 'delete with model, random code',
             is_array: false,
             success: { code: 203, model: Foo, message: 'deleted' }
        delete '/deleteme203' do
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
    expect(subject['paths'].map { |_, p| p['delete']['responses'] }).to eql(
      [
        { '200' => { 'description' => 'deleted', 'schema' => { '$ref' => '#/definitions/Foo' } } },
        { '200' => { 'description' => 'deleted', 'schema' => { '$ref' => '#/definitions/Foo' } } },
        { '203' => { 'description' => 'deleted' }, '200' => { 'schema' => { '$ref' => '#/definitions/Foo' } } }
      ]
    )
  end
end
