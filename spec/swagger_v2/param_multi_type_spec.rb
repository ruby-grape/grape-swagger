# frozen_string_literal: true

require 'spec_helper'

describe 'Params Multi Types' do
  def app
    Class.new(Grape::API) do
      format :json

      desc 'action' do
        consumes ['application/x-www-form-urlencoded']
      end
      params do
        requires :input, types: [String, Integer]
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

  describe 'with non-string primary type' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'action' do
          consumes ['application/x-www-form-urlencoded']
        end
        params do
          requires :int_first, type: [Integer, Float]
          requires :int_via_types, types: [Integer, Float]
          optional :float_opt, type: [Integer, Float]
          requires :nested_group, type: Hash do
            requires :nested_int, type: [Integer, Float]
          end
        end
        post :action do
          { message: 'hi' }
        end

        add_swagger_documentation
      end
    end

    it 'recovers the first variant type, not a hardcoded fallback' do
      types = subject.to_h { |p| [p['name'], p['type']] }
      expect(types['int_first']).to eq('integer')
      expect(types['int_via_types']).to eq('integer')
      expect(types['float_opt']).to eq('integer')
      expect(types['nested_group[nested_int]']).to eq('integer')
    end
  end

  describe 'with non-string primary type in a namespace' do
    def app
      Class.new(Grape::API) do
        format :json

        namespace :ns do
          desc 'action' do
            consumes ['application/x-www-form-urlencoded']
          end
          params do
            requires :val, type: [Integer, Float]
          end
          post(:action) { nil }
        end

        add_swagger_documentation
      end
    end

    subject do
      get '/swagger_doc'
      expect(last_response.status).to eq 200
      body = JSON.parse last_response.body
      body['paths']['/ns/action']['post']['parameters']
    end

    it 'recovers the first variant type' do
      types = subject.to_h { |p| [p['name'], p['type']] }
      expect(types['val']).to eq('integer')
    end
  end

  # Canary tests for Grape internals used by collect_variant_types.
  # Fails after a Grape upgrade? Update collect_variant_types to match the new
  # validator shape. Grape 3.2+: Hash entries (key lookups). Older supported
  # versions: object instances (private-ivar reads).
  describe 'Grape internal contract for collect_variant_types' do
    before { skip unless defined?(Grape::Validations::Types::VariantCollectionCoercer) }

    it '@types is readable on VariantCollectionCoercer' do
      coercer = Grape::Validations::Types::VariantCollectionCoercer.new([Integer, Float])
      expect(coercer.instance_variable_defined?(:@types)).to be(true)
      expect(coercer.instance_variable_get(:@types).to_a).to eq([Integer, Float])
    end

    describe 'CoerceValidator validation entries' do
      let(:parser) do
        GrapeSwagger::RequestParamParsers::Route.new(nil, nil, nil, nil)
      end

      let(:route) do
        Class.new(Grape::API) do
          params { requires :n, type: [Integer, Float] }
          get(:x) { nil }
        end.routes.first
      end

      let(:coerce_validator) do
        sv = route.app&.inheritable_setting&.namespace_stackable
        return nil unless sv.respond_to?(:[])

        sv[:validations].find do |v|
          v.is_a?(Hash) ? v[:validator_class] == Grape::Validations::Validators::CoerceValidator : v.is_a?(Grape::Validations::Validators::CoerceValidator)
        end
      end

      it 'finds a CoerceValidator entry in a supported shape' do
        expect(coerce_validator).not_to be_nil
      end

      it 'processes a Hash-shaped validator entry (unit test of entry-parsing logic)' do
        scope = Struct.new(:name) do
          def full_name(attr)
            attr.to_s
          end
        end.new('n')

        stackable_values = {
          validations: [{
            validator_class: Grape::Validations::Validators::CoerceValidator,
            attributes: [:n],
            params_scope: scope,
            options: { type: Grape::Validations::Types::VariantCollectionCoercer.new([Integer, Float]) }
          }]
        }

        expect(parser.send(:collect_variant_types, stackable_values)).to eq('n' => [Integer, Float])
      end

      it 'exposes scope and converter state needed for recovery' do
        expect(coerce_validator).not_to be_nil

        if coerce_validator.is_a?(Hash)
          expect(coerce_validator[:attributes]).to include(:n)
          expect(coerce_validator[:params_scope]).to respond_to(:full_name)
          expect(coerce_validator[:options]).to have_key(:type)
          expect(coerce_validator[:options][:type]).to be_a(Grape::Validations::Types::VariantCollectionCoercer)
        else
          expect(coerce_validator.attrs).to include(:n)
          expect(coerce_validator.instance_variable_get(:@scope)).to respond_to(:full_name)
          expect(coerce_validator.instance_variable_get(:@converter)).to be_a(Grape::Validations::Types::VariantCollectionCoercer)
        end
      end
    end
  end

  describe 'with same param name declared twice before the same route' do
    def app
      Class.new(Grape::API) do
        format :json
        desc 'action' do
          consumes ['application/x-www-form-urlencoded']
        end
        params { requires :n, type: [Integer, Float] }
        params { requires :n, type: [String, Integer] }
        post(:action) { nil }
        add_swagger_documentation
      end
    end

    it 'uses the last-declared type' do
      # Relies on validators being iterated in declaration order; last write wins.
      types = subject.to_h { |p| [p['name'], p['type']] }
      expect(types['n']).to eq('string')
    end
  end

  describe 'header params' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Some API',
             consumes: ['application/x-www-form-urlencoded'],
             headers: { 'My-Header' => { required: true, description: 'Set this!' } }
        params do
          requires :input, types: [String, Integer]
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
