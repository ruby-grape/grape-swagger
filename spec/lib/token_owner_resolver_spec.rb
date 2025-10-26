# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::TokenOwnerResolver do
  describe '.resolve' do
    let(:helper_module) do
      Module.new do
        def current_user_id
          'user-123'
        end
      end
    end

    let(:api_class) do
      mod = helper_module
      Class.new(Grape::API) do
        helpers mod

        helpers do
          def token_owner
            { id: 7, email: 'owner@example.com' }
          end
        end

        get('/status') { { status: 'ok' } }
      end
    end

    before { api_class.compile! }

    let(:endpoint) { api_class.endpoints.first }

    it 'returns nil when no method name is provided' do
      expect(described_class.resolve(endpoint, nil)).to be_nil
    end

    it 'returns the resolved value when method exists' do
      expect(described_class.resolve(endpoint, :token_owner)).to eq(id: 7, email: 'owner@example.com')
    end

    it 'raises when the endpoint does not respond to the method' do
      expect do
        expect(described_class.resolve(endpoint, :unknown))
      end.to raise_error(GrapeSwagger::Errors::TokenOwnerNotFound, /undefined method `unknown`/)
    end

    context 'when helpers are included from a module' do
      it 'resolves the owner using the helper module from the namespace stack' do
        expect(described_class.resolve(endpoint, :current_user_id)).to eq('user-123')
      end
    end
  end

  describe '.evaluate_proc' do
    let(:token_owner) { double(:token_owner) }

    it 'executes callables without arguments directly' do
      callable = -> { :owner }

      expect(callable).to receive(:call).with(no_args).and_call_original
      expect(described_class.evaluate_proc(callable, token_owner)).to eq(:owner)
    end

    it 'passes the token owner when the callable accepts an argument' do
      callable = ->(owner) { owner }

      allow(callable).to receive(:call).with(token_owner).and_call_original
      expect(described_class.evaluate_proc(callable, token_owner)).to eq(token_owner)
      expect(callable).to have_received(:call).with(token_owner)
    end

    it 'defaults to calling without arguments when arity cannot be detected' do
      callable = Class.new do
        def call(owner = :undetected)
          owner
        end
      end.new

      expect(described_class.evaluate_proc(callable, token_owner)).to eq(:undetected)
    end
  end

  describe '.resolve_from_helper' do
    let(:helper_module) do
      Module.new do
        def helper_method
          'helper_result'
        end
      end
    end

    let(:endpoint) { instance_double(Grape::Endpoint) }

    it 'resolves the method from the Module helper' do
      result = described_class.send(:resolve_from_helper, endpoint, helper_module, :helper_method)
      expect(result).to eq('helper_result')
    end

    it 'returns a frozen sentinel object when method does not exist on the Module' do
      result = described_class.send(:resolve_from_helper, endpoint, helper_module, :nonexistent)
      # UNRESOLVED is a private constant, so we check by type and behavior
      expect(result).to be_a(Object)
      expect(result).to be_frozen
      # Verify it's the same object on repeated calls (singleton pattern)
      result2 = described_class.send(:resolve_from_helper, endpoint, helper_module, :nonexistent)
      expect(result).to equal(result2)
    end
  end

  describe 'endpoint helpers access' do
    let(:helper_module) do
      Module.new do
        def current_user
          { id: 42, name: 'Test User' }
        end
      end
    end

    let(:api_class) do
      mod = helper_module
      Class.new(Grape::API) do
        helpers mod

        get('/test') { { ok: true } }
      end
    end

    before { api_class.compile! }

    let(:endpoint) { api_class.endpoints.first }

    it 'resolves helper methods from namespace stack' do
      resolved_value = described_class.resolve(endpoint, :current_user)
      expect(resolved_value).to eq(id: 42, name: 'Test User')
    end
  end
end
