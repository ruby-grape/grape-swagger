require 'spec_helper'

describe 'Params Types' do
  def app
    Class.new(Grape::API) do
      format :json

      params do
        requires :input, type: String
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
    body['paths']["/action"]['post']['parameters']
  end

  it 'reads param type correctly' do
    expect(subject).to eq [{
      "in"=>"formData",
      "name"=>"input",
      "type"=>"string",
      "required"=>true
    }]
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
