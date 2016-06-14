require 'spec_helper'

describe GrapeSwagger::DocMethods::MoveParams do
  include_context 'the api paths/defs'

  subject { described_class }

  it { expect(subject.to_s).to eql 'GrapeSwagger::DocMethods::MoveParams' }

  describe 'find_post_put' do
    let(:paths) { {} }

    describe 'paths empty' do
      specify { expect { |b| subject.find_post_put(paths, &b) }.not_to yield_control }
    end

    describe 'no post/put given' do
      let(:paths) do
        {
          :'/foo' => { get: {}, delete: {} },
          :'/bar/{key}' => { get: {}, delete: {} }
        }
      end
      specify { expect { |b| subject.find_post_put(paths, &b) }.not_to yield_control }
    end

    describe 'no post/put given' do
      let(:paths) do
        {
          :'/foo' => { get: {}, delete: {}, post: {}, put: {}, patch: {} },
          :'/bar/{key}' => { get: {}, delete: {}, post: {}, put: {}, patch: {} }
        }
      end
      let(:expected) do
        [
          { post: {}, put: {}, patch: {} },
          { post: {}, put: {}, patch: {} }
        ]
      end
      specify { expect { |b| subject.find_post_put(paths, &b) }.to yield_control.twice }
      specify { expect { |b| subject.find_post_put(paths, &b) }.to yield_successive_args *expected }
    end
  end

  describe 'find_definition_and_params' do
    specify do
      subject.instance_variable_set(:@definitions, definitions)
      subject.find_definition_and_params(found_path[:post], :post)
      expect(definitions.keys).to include 'InBody'
      expect(definitions['postRequestInBody'].keys).to_not include :description
    end
  end

  describe 'move_params_to_new definition' do
    let(:name) { 'Foo' }
    let(:definitions) { {} }

    describe 'post request' do
      let(:verb) { 'post' }
      let(:params) { paths['/in_body'][:post][:parameters] }

      specify do
        subject.instance_variable_set(:@definitions, definitions)
        name = subject.send(:build_definition, name, verb)
        subject.move_params_to_new(name, params)

        expect(definitions[name]).to eql expected_post_defs
        expect(params).to be_empty
      end
    end

    describe 'put request' do
      let(:verb) { 'put' }
      let(:params) { paths['/in_body/{key}'][:put][:parameters] }

      specify do
        subject.instance_variable_set(:@definitions, definitions)
        name, definition = subject.send(:build_definition, name, verb)
        subject.move_params_to_new(name, params)

        expect(definitions[name]).to eql expected_put_defs
        expect(params.length).to be 1
      end
    end
  end

  describe 'nested definitions related' do
    describe 'prepare_nested_names' do
      before do
        subject.send(:prepare_nested_names, params)
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
        let(:params) { [{ in: 'body', name: 'address[][street_lines]', description: 'street lines', type: 'array', required: true }] }
        let(:expected) { [{ in: 'body', name: 'street_lines', description: 'street lines', type: 'array', required: true }] }
        specify do
          expect(params).to eql expected
        end
      end
    end
  end

  describe 'private methods' do
    describe 'build_definition' do
      before do
        subject.instance_variable_set(:@definitions, definitions)
        subject.send(:build_definition, name, verb)
      end

      describe 'verb given' do
        let(:verb) { 'post' }
        let(:name) { 'Foo' }
        let(:definitions) { {} }

        specify do
          definition = definitions.to_a.first
          expect(definition.first).to eql 'postRequestFoo'
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
      let(:response) { { schema: { '$ref' => '#/definitions/Somewhere' } } }

      describe 'no name given' do
        let(:name) { nil }
        let(:expected_param) do
          { name: 'Somewhere', in: 'body', required: true, schema: { '$ref' => '#/definitions/Somewhere' } }
        end
        specify do
          parameter = subject.send(:build_body_parameter, response)
          expect(parameter).to eql expected_param
        end
      end

      describe 'name given' do
        let(:name) { 'Foo' }
        let(:expected_param) do
          { name: 'Somewhere', in: 'body', required: true, schema: { '$ref' => "#/definitions/#{name}" } }
        end
        specify do
          parameter = subject.send(:build_body_parameter, response, name)
          expect(parameter).to eql expected_param
        end
      end
    end

    describe 'parse_model' do
      let(:ref) { '#/definitions/InBody' }
      subject(:object) { described_class.send(:parse_model, ref) }

      specify { expect(object).to eql 'InBody' }
    end

    describe 'movable' do
      describe 'path' do
        let(:param) { { in: 'path', name: 'key', description: nil, type: 'integer', format: 'int32', required: true } }
        it { expect(subject.send(:movable?, param)).to be false }
      end

      describe 'body' do
        let(:param) { { in: 'body', name: 'in_body', description: 'in_body', type: 'integer', format: 'int32', required: true } }
        it { expect(subject.send(:movable?, param)).to be true }
      end

      describe 'query' do
        let(:param) { { in: 'query', name: 'in_query', description: 'in_query', type: 'integer', format: 'int32', required: true } }
        it { expect(subject.send(:movable?, param)).to be false }
      end

      describe 'header' do
        let(:param) { { in: 'header', name: 'in_header', description: 'in_header', type: 'integer', format: 'int32', required: true } }
        it { expect(subject.send(:movable?, param)).to be false }
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

    describe 'should move' do
      describe 'no move' do
        let(:params) do
          [
            { in: 'path', name: 'key', description: nil, type: 'integer', format: 'int32', required: true },
            { in: 'formData', name: 'in_form_data', description: 'in_form_data', type: 'integer', format: 'int32', required: true }
          ]
        end
        it { expect(subject.send(:should_move?, params)).to be false }
      end

      describe 'move' do
        let(:params) do
          [
            { in: 'path', name: 'key', description: nil, type: 'integer', format: 'int32', required: true },
            { in: 'body', name: 'in_bosy', description: 'in_bosy', type: 'integer', format: 'int32', required: true },
            { in: 'formData', name: 'in_form_data', description: 'in_form_data', type: 'integer', format: 'int32', required: true }
          ]
        end
        it { expect(subject.send(:should_move?, params)).to be true }
      end
    end

    describe 'unify' do
      before do
        subject.send(:unify!, params) if subject.send(:should_move?, params)
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
