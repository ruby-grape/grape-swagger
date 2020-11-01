# frozen_string_literal: true

require 'spec_helper'

describe 'Params Multi Types' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        if Grape::VERSION < '0.14'
          requires :input, type: [String, Integer]
        else
          requires :input, types: [String, Integer]
        end
        requires :another_input, type: [String, Integer]
      end
      post :action do
        { message: 'hi' }
      end

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc/action'
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    body['paths']['/action']['post']['parameters']
  end

  it 'reads param type correctly' do
    expect(subject).to eq [
      {
        'in' => 'formData',
        'name' => 'input',
        'type' => 'string',
        'required' => true
      },
      {
        'in' => 'formData',
        'name' => 'another_input',
        'type' => 'string',
        'required' => true
      }
    ]
  end

  describe 'header params' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Some API', headers: { 'My-Header' => { required: true, description: 'Set this!' } }
        params do
          if Grape::VERSION < '0.14'
            requires :input, type: [String, Integer]
          else
            requires :input, types: [String, Integer]
          end
          requires :another_input, type: [String, Integer]
        end
        post :action do
          { message: 'hi' }
        end

        add_swagger_documentation
      end
    end

    it 'has consistent types' do
      types = subject.map { |param| param['type'] }
      expect(types).to eq(%w[string string string])
    end
  end
end
