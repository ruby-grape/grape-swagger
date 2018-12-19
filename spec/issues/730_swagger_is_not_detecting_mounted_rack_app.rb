# frozen_string_literal: true

require 'spec_helper'

require 'grape-swagger/entity'

module API
  module V1
    class Welcome < Grape::API
      desc 'Greets user' do
        detail 'This is the root api and it will greet user on accessing'
      end
      get "/" do
        {
          data: [
            { message: "Welcome to notes app" }
          ]
        }
      end
    end
  end
end

module API
  module V1
    class Base < Grape::API
      version :v1, using: :path

      mount Welcome
    end
  end
end

module API
  class Base < Grape::API
    format :json
    prefix :api

    mount V1::Base

    add_swagger_documentation hide_documentation_path: true,
                              version: "V1",
                              info: {
                                title: 'User notes app',
                                description: 'Demo app for user notes'
                              }
  end
end

describe 'swagger is not detecting mounted rack app' do
  let(:app) { API::Base }

  context 'when a rack app is mounted under API::Base' do

    context 'when api/v1/ is called' do
      subject do
        get '/api/v1'
        JSON.parse(last_response.body)
      end

      it 'checks if the response is correct' do
        expect(subject).to eq({"data"=>[{"message"=>"Welcome to notes app"}]})
      end
    end

    context 'when api/swagger_doc is called' do
      subject do
        get '/api/swagger_doc'
        JSON.parse(last_response.body)
      end

      it 'checks if the swagger documentation is properly generated' do
        expect(subject["paths"]).to_not be_nil
      end
    end
  end
end