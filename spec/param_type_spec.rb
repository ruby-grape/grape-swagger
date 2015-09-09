require 'spec_helper'

describe 'Params Types' do
  def app
    Class.new(Grape::API) do
      format :json

      desc 'description', nickname: 'desc', params: { input1: { type: Integer, param_type: 'query' } }
      params do
        requires :input2, type: String, documentation: { param_type: 'query' }
      end
      post :action do
      end

      add_swagger_documentation
    end
  end

  subject do
    get '/swagger_doc/action'
    expect(last_response.status).to eq 200
    body = JSON.parse last_response.body
    body['apis'].first['operations'].flat_map { |o| o['parameters'] }
  end

  it 'reads param type correctly' do
    expect(subject).to match_array [
      { 'paramType' => 'query', 'name' => 'input1', 'description' => '', 'type' => 'integer', 'required' => false, 'allowMultiple' => false, 'format' => 'int32' },
      { 'paramType' => 'query', 'name' => 'input2', 'description' => '', 'type' => 'string', 'required' => true, 'allowMultiple' => false }
    ]
  end

  describe 'header params' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Some API', headers: { 'My-Header' => { required: true, description: 'Set this!' } }
        params do
          requires :input, type: String
        end
        post :action do
        end

        add_swagger_documentation
      end
    end

    it 'has consistent types' do
      types = subject.map { |param| param['type'] }
      expect(types).to eq(%w(string string))
    end
  end
end
