# frozen_string_literal: true

require 'spec_helper'

describe 'Params Types' do
  def app
    Class.new(Grape::API) do
      format :json

      desc 'action' do
        consumes ['application/x-www-form-urlencoded']
      end
      params do
        requires :input, type: String
      end
      post :action do
        { message: 'hi' }
      end

      desc 'action_with_doc' do
        consumes ['application/x-www-form-urlencoded']
      end
      params do
        requires :input, type: String, default: '14', documentation: { type: 'email', default: '42' }
      end
      post :action_with_doc do
        { message: 'hi' }
      end

      if Gem::Version.new(Grape::VERSION) >= Gem::Version.new('2.1.0')
        desc 'other_action' do
          consumes ['application/x-www-form-urlencoded']
        end
        params do
          requires :input, type: String, length: { min: 1, max: 12 }
          requires :arr, type: [Integer], length: { min: 1, max: 12 }
        end
        post :other_action do
          { message: 'hi' }
        end
      end

      add_swagger_documentation
    end
  end

  context 'when length validator is used', if: Gem::Version.new(Grape::VERSION) >= Gem::Version.new('2.1.0') do
    subject do
      get '/swagger_doc/other_action'
    end

    it 'documents the length/item limits correctly' do
      subject

      expect(last_response.status).to eq 200
      expect(JSON.parse(last_response.body)['paths']['/other_action']['post']['parameters']).to eq([{
        'in' => 'formData',
        'maxLength' => 12,
        'minLength' => 1,
        'name' => 'input',
        'required' => true,
        'type' => 'string'
      }, {
        'in' => 'formData',
        'items' => { 'format' => 'int32', 'type' => 'integer' },
        'maxItems' => 12,
        'minItems' => 1,
        'name' => 'arr',
        'required' => true,
        'type' => 'array'
      }])
    end
  end

  context 'with no documentation hash' do
    subject do
      get '/swagger_doc/action'
      expect(last_response.status).to eq 200
      body = JSON.parse last_response.body
      body['paths']['/action']['post']['parameters']
    end

    it 'reads param type correctly' do
      expect(subject).to eq [{
        'in' => 'formData',
        'name' => 'input',
        'type' => 'string',
        'required' => true
      }]
    end

    describe 'header params' do
      def app
        Class.new(Grape::API) do
          format :json

          desc 'Some API',
               consumes: ['application/x-www-form-urlencoded'],
               headers: { 'My-Header' => { required: true, description: 'Set this!' } }
          params do
            requires :input, type: String
          end
          post :action do
            { message: 'hi' }
          end

          add_swagger_documentation
        end
      end

      it 'has consistent types' do
        types = subject.map { |param| param['type'] }
        expect(types).to eq(%w[string string])
      end
    end
  end

  context 'with documentation hash' do
    subject do
      get '/swagger_doc/action_with_doc'
      expect(last_response.status).to eq 200
      body = JSON.parse last_response.body
      body['paths']['/action_with_doc']['post']['parameters']
    end

    it 'reads param type correctly' do
      expect(subject).to eq [{
        'in' => 'formData',
        'name' => 'input',
        'type' => 'string',
        'format' => 'email',
        'default' => '42',
        'required' => true
      }]
    end
  end
end
