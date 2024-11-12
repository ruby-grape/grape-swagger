# frozen_string_literal: true

require 'spec_helper'

describe 'default endpoint visibility' do
  let(:documentation_options) do
    { default_route_visibility: default_visibility }
  end
  let(:app) do
    swagger_options = documentation_options
    options = route_options

    Class.new(Grape::API) do
      desc 'Get all accounts', options
      resource :accounts do
        get do
          [{ message: 'hello world' }]
        end
      end

      add_swagger_documentation(swagger_options)
    end
  end

  shared_examples 'public endpoint' do
    it 'exposes endpoint' do
      get_route = subject.dig('paths', '/accounts', 'get')
      expect(get_route).to be_present
      expect(get_route['description']).to eq 'Get all accounts'
    end
  end

  shared_examples 'hidden endpoint' do
    it 'hides endpoint' do
      expect(subject.dig('paths', '/accounts')).to be_nil
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  context 'with :public default visibility' do
    let(:default_visibility) { :public }

    context 'with endpoint marked hidden: true' do
      let(:route_options) do
        { hidden: true }
      end

      it_behaves_like 'hidden endpoint'
    end

    context 'with endpoint marked public: true' do
      let(:route_options) do
        { public: true }
      end

      it_behaves_like 'public endpoint'
    end

    context 'with blank endpoint options' do
      let(:route_options) do
        {}
      end

      it_behaves_like 'public endpoint'
    end

    context 'with endpoint marked hidden: false' do
      let(:route_options) do
        { hidden: false }
      end

      it_behaves_like 'public endpoint'
    end

    context 'with endpoint marked public: false' do
      let(:route_options) do
        { public: false }
      end

      it_behaves_like 'public endpoint'
    end
  end

  context 'with :hidden default visibility' do
    let(:default_visibility) { :hidden }

    context 'with endpoint marked public: true' do
      let(:route_options) do
        { public: true }
      end

      it_behaves_like 'public endpoint'
    end

    context 'with endpoint marked hidden: true' do
      let(:route_options) do
        { hidden: true }
      end

      it_behaves_like 'hidden endpoint'
    end

    context 'with blank endpoint options' do
      let(:route_options) do
        {}
      end

      it_behaves_like 'hidden endpoint'
    end

    context 'with endpoint marked public: false' do
      let(:route_options) do
        { public: false }
      end

      it_behaves_like 'hidden endpoint'
    end

    context 'with endpoint marked hidden: false' do
      let(:route_options) do
        { hidden: false }
      end

      it_behaves_like 'hidden endpoint'
    end
  end

  context 'with no visibility specified' do
    let(:documentation_options) do
      {}
    end

    context 'with endpoint marked public: true' do
      let(:route_options) do
        { public: true }
      end

      it_behaves_like 'public endpoint'
    end

    context 'with endpoint marked hidden: true' do
      let(:route_options) do
        { hidden: true }
      end

      it_behaves_like 'hidden endpoint'
    end

    context 'with blank endpoint options' do
      let(:route_options) do
        {}
      end

      it_behaves_like 'public endpoint'
    end

    context 'with endpoint marked public: false' do
      let(:route_options) do
        { public: false }
      end

      it_behaves_like 'public endpoint'
    end

    context 'with endpoint marked hidden: false' do
      let(:route_options) do
        { hidden: false }
      end

      it_behaves_like 'public endpoint'
    end
  end
end
