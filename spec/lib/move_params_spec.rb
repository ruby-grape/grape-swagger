require 'spec_helper'

describe GrapeSwagger::DocMethods::MoveParams do
  include_context 'the api paths/defs'

  subject { described_class }

  it { expect(subject.to_s).to eql 'GrapeSwagger::DocMethods::MoveParams' }

  describe 'parameters can_be_moved' do
    let(:movable_params) do
      [
        { param_type: 'path', name: 'key', description: nil, type: 'integer', format: 'int32', required: true },
        { param_type: 'body', name: 'in_body', description: 'in_body', type: 'integer', format: 'int32', required: true },
        { param_type: 'query', name: 'in_query', description: 'in_query', type: 'integer', format: 'int32', required: true },
        { param_type: 'header', name: 'in_header', description: 'in_header', type: 'integer', format: 'int32', required: true },
        { param_type: 'formData', name: 'in_form_data', description: 'in_form_data', type: 'integer', format: 'int32', required: true }
      ]
    end

    let(:not_movable_params) do
      [
        { in: 'path', name: 'key', description: nil, type: 'integer', format: 'int32', required: true },
        { in: 'query', name: 'in_query', description: 'in_query', type: 'integer', format: 'int32', required: true },
        { in: 'header', name: 'in_header', description: 'in_header', type: 'integer', format: 'int32', required: true },
        { in: 'formData', name: 'in_form_data', description: 'in_form_data', type: 'integer', format: 'int32', required: true }
      ]
    end

    let(:allowed_verbs) do
      [:post, :put, :patch, 'POST', 'PUT', 'PATCH']
    end

    let(:not_allowed_verbs) do
      [:get, :delete, 'GET', 'DELETE']
    end

    describe 'movable params' do
      specify 'allowed verbs' do
        allowed_verbs.each do |verb|
          expect(subject.can_be_moved?(movable_params, verb)).to be true
        end
      end

      specify 'not allowed verbs' do
        not_allowed_verbs.each do |verb|
          expect(subject.can_be_moved?(movable_params, verb)).to be false
        end
      end
    end

    describe 'not movable params' do
      specify 'allowed verbs' do
        allowed_verbs.each do |verb|
          expect(subject.can_be_moved?(not_movable_params, verb)).to be false
        end
      end

      specify 'not allowed verbs' do
        not_allowed_verbs.each do |verb|
          expect(subject.can_be_moved?(not_movable_params, verb)).to be false
        end
      end
    end

    describe 'movable_params' do
      before do
        subject.send(:unify!, movable_params)
      end
      let(:expected_params) do
        [
          { in: 'path', name: 'key', description: nil, type: 'integer', format: 'int32', required: true },
          { in: 'query', name: 'in_query', description: 'in_query', type: 'integer', format: 'int32', required: true },
          { in: 'header', name: 'in_header', description: 'in_header', type: 'integer', format: 'int32', required: true }
        ]
      end

      let(:expected_movable_params) do
        [
          { in: 'body', name: 'in_body', description: 'in_body', type: 'integer', format: 'int32', required: true },
          { in: 'body', name: 'in_form_data', description: 'in_form_data', type: 'integer', format: 'int32', required: true }
        ]
      end

      specify do
        params_to_move = subject.send(:movable_params, movable_params)
        expect(movable_params).to eql expected_params
        expect(params_to_move).to eql expected_movable_params
      end
    end
  end

  describe 'parent_definition_of_params' do
    describe 'POST' do
      let(:params) { paths['/in_body'][:post][:parameters] }
      let(:options)  do
        {
          method: 'POST'
        }
      end
      let(:env) { Rack::MockRequest.env_for('/in_body', options) }
      let(:request) { Grape::Request.new(env) }

      specify do
        subject.to_definition(params, request, definitions)
        expect(params).to eql(
          [
            { name: 'InBody', in: 'body', required: true, schema: { '$ref' => '#/definitions/postInBody' } }
          ]
        )
        expect(subject.definitions['postInBody']).not_to include :description
        expect(subject.definitions['postInBody']).to eql expected_post_defs
      end
    end

    describe 'POST' do
      let(:params) { paths['/in_body/{key}'][:put][:parameters] }
      let(:options)  do
        {
          method: 'PUT'
        }
      end
      let(:env) { Rack::MockRequest.env_for('/in_body', options) }
      let(:request) { Grape::Request.new(env) }

      specify do
        subject.to_definition(params, request, definitions)
        expect(params).to eql(
          [
            { in: 'path', name: 'key', description: nil, type: 'integer', format: 'int32', required: true },
            { name: 'InBody', in: 'body', required: true, schema: { '$ref' => '#/definitions/putInBody' } }
          ]
        )
        expect(subject.definitions['putInBody']).not_to include :description
        expect(subject.definitions['putInBody']).to eql expected_put_defs
      end
    end
  end

  describe 'nested definitions related' do
    describe 'prepare_nested_names' do
      let(:property) { 'address' }
      before do
        subject.send(:prepare_nested_names, property, params)
      end

      describe 'simple' do
        let(:params) { [{ in: 'body', name: 'address[street]', description: 'street', type: 'string', required: true }] }
        let(:expected) { [{ in: 'body', name: 'street', description: 'street', type: 'string', required: true }] }
        specify do
          expect(params).to eql expected
        end
      end

      describe 'nested' do
        let(:params) { [{ in: 'body', name: 'address[street][name]', description: 'street', type: 'string', required: true }] }
        let(:expected) { [{ in: 'body', name: 'street[name]', description: 'street', type: 'string', required: true }] }
        specify do
          expect(params).to eql expected
        end
      end

      describe 'array' do
        let(:params) { [{ in: 'body', name: 'address[street_lines]', description: 'street lines', type: 'array', items: { type: 'string' }, required: true }] }
        let(:expected) { [{ in: 'body', name: 'street_lines', description: 'street lines', type: 'array', items: { type: 'string' }, required: true }] }
        specify do
          expect(params).to eql expected
        end
      end
    end
  end

  describe 'private methods' do
    describe 'build_definition' do
      let(:params) { [{ in: 'body', name: 'address[street][name]', description: 'street', type: 'string', required: true }] }
      before do
        subject.instance_variable_set(:@definitions, definitions)
        subject.send(:build_definition, name, params, verb)
      end

      describe 'verb given' do
        let(:verb) { 'post' }
        let(:name) { 'Foo' }
        let(:definitions) { {} }

        specify do
          definition = definitions.to_a.first
          expect(definition.first).to eql 'postFoo'
          expect(definition.last).to eql(type: 'object', properties: {}, required: [])
        end
      end

      describe 'no verb given' do
        let(:name) { 'FooBar' }
        let(:definitions) { {} }
        let(:verb) { nil }

        specify do
          definition = definitions.to_a.first
          expect(definition.first).to eql 'FooBar'
          expect(definition.last).to eql(type: 'object', properties: {}, required: [])
        end
      end
    end

    describe 'build_body_parameter' do
      describe 'name given' do
        let(:name) { 'Foo' }
        let(:reference) { 'Bar' }
        let(:expected_param) do
          { name: name, in: 'body', required: true, schema: { '$ref' => "#/definitions/#{reference}" } }
        end
        specify do
          parameter = subject.send(:build_body_parameter, reference, name)
          expect(parameter).to eql expected_param
        end
      end
    end

    describe 'parse_model' do
      let(:ref) { '#/definitions/InBody' }
      describe 'post request' do
        subject(:object) { described_class.send(:parse_model, ref) }

        specify { expect(object).to eql ref }
      end

      describe 'post request' do
        let(:put_ref) { '#/definitions/InBody/{id}' }
        subject(:object) { described_class.send(:parse_model, put_ref) }

        specify { expect(object).to eql ref }
      end
    end

    describe 'deletable' do
      describe 'path' do
        let(:param) { { in: 'path', name: 'key', description: nil, type: 'integer', format: 'int32', required: true } }
        it { expect(subject.send(:deletable?, param)).to be false }
      end

      describe 'body' do
        let(:param) { { in: 'body', name: 'in_body_1', description: 'in_body_1', type: 'integer', format: 'int32', required: true } }
        it { expect(subject.send(:deletable?, param)).to be true }
      end

      describe 'query' do
        let(:param) { { in: 'query', name: 'in_query_1', description: 'in_query_1', type: 'integer', format: 'int32', required: true } }
        it { expect(subject.send(:deletable?, param)).to be false }
      end

      describe 'header' do
        let(:param) { { in: 'header', name: 'in_header_1', description: 'in_header_1', type: 'integer', format: 'int32', required: true } }
        it { expect(subject.send(:deletable?, param)).to be false }
      end
    end

    describe 'unify' do
      before :each do
        subject.send(:unify!, params)
      end
      describe 'param type with `:in` given' do
        let(:params) do
          [
            { in: 'path', name: 'key', description: nil, type: 'integer', format: 'int32', required: true },
            { in: 'body', name: 'in_body', description: 'in_body', type: 'integer', format: 'int32', required: true },
            { in: 'query', name: 'in_query', description: 'in_query', type: 'integer', format: 'int32', required: true },
            { in: 'header', name: 'in_header', description: 'in_header', type: 'integer', format: 'int32', required: true },
            { in: 'formData', name: 'in_form_data', description: 'in_form_data', type: 'integer', format: 'int32', required: true }
          ]
        end

        let(:expected_params) do
          [
            { in: 'path', name: 'key', description: nil, type: 'integer', format: 'int32', required: true },
            { in: 'body', name: 'in_body', description: 'in_body', type: 'integer', format: 'int32', required: true },
            { in: 'query', name: 'in_query', description: 'in_query', type: 'integer', format: 'int32', required: true },
            { in: 'header', name: 'in_header', description: 'in_header', type: 'integer', format: 'int32', required: true },
            { in: 'body', name: 'in_form_data', description: 'in_form_data', type: 'integer', format: 'int32', required: true }
          ]
        end
        it { expect(params).to eql expected_params }
      end

      describe 'let it as is' do
        let(:params) do
          [
            { in: 'path', name: 'key', description: nil, type: 'integer', format: 'int32', required: true },
            { in: 'formData', name: 'in_form_data', description: 'in_form_data', type: 'integer', format: 'int32', required: true }
          ]
        end

        let(:expected_params) do
          [
            { in: 'path', name: 'key', description: nil, type: 'integer', format: 'int32', required: true },
            { in: 'formData', name: 'in_form_data', description: 'in_form_data', type: 'integer', format: 'int32', required: true }
          ]
        end
        it { expect(params).to eql expected_params }
      end

      describe 'param type with `:param_type` given' do
        let(:params) do
          [
            { param_type: 'path', name: 'key', description: nil, type: 'integer', format: 'int32', required: true },
            { param_type: 'body', name: 'in_body', description: 'in_body', type: 'integer', format: 'int32', required: true },
            { param_type: 'query', name: 'in_query', description: 'in_query', type: 'integer', format: 'int32', required: true },
            { param_type: 'header', name: 'in_header', description: 'in_header', type: 'integer', format: 'int32', required: true },
            { param_type: 'formData', name: 'in_form_data', description: 'in_form_data', type: 'integer', format: 'int32', required: true }
          ]
        end

        let(:expected_params) do
          [
            { name: 'key', description: nil, type: 'integer', format: 'int32', required: true, in: 'path' },
            { name: 'in_body', description: 'in_body', type: 'integer', format: 'int32', required: true, in: 'body' },
            { name: 'in_query', description: 'in_query', type: 'integer', format: 'int32', required: true, in: 'query' },
            { name: 'in_header', description: 'in_header', type: 'integer', format: 'int32', required: true, in: 'header' },
            { name: 'in_form_data', description: 'in_form_data', type: 'integer', format: 'int32', required: true, in: 'body' }
          ]
        end
        it { expect(params).to eql expected_params }
      end
    end
  end
end
