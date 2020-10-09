# frozen_string_literal: true

require 'spec_helper'

describe '#605 root route documentation' do
  let(:app) do
    Class.new(Grape::API) do
      resource :grunnbeløp do
        desc 'returnerer grunnbeløp'
        get do
          { message: 'hello world' }
        end
      end

      resource :εσόδων do
        desc 'εσόδων'
        get do
          { message: 'hello world' }
        end
      end

      resource :数 do
        desc '数'
        get do
          { message: 'hello world' }
        end
      end

      resource :amount do
        desc 'returns amount'
        get do
          { message: 'hello world' }
        end
      end

      resource :👍 do
        desc 'returns 👍'
        get do
          { message: 'hello world' }
        end
      end

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)['paths']
  end

  specify do
    expect(subject.keys).to match_array ['/grunnbeløp', '/amount', '/εσόδων', '/数']
  end
end
