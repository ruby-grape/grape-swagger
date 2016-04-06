require 'spec_helper'

describe GrapeSwagger::DocMethods::MoveParams do
  include_context "the api paths/defs"

  subject { described_class }

  it { expect(subject.to_s).to eql 'GrapeSwagger::DocMethods::MoveParams' }

  describe 'find_post_put' do
    let(:paths) { {} }

    describe 'paths empty' do
      specify { expect { |b| subject.find_post_put(paths, &b) }.not_to yield_control }
    end

    describe 'no post/put given' do
      let(:paths) {{
        :'/foo'=> { get: {}, delete: {}},
        :'/bar/{key}'=> { get: {}, delete: {}},
      }}
      specify { expect { |b| subject.find_post_put(paths, &b) }.not_to yield_control }
    end

    describe 'no post/put given' do
      let(:paths) {{
        :'/foo'=> { get: {}, delete: {}, post: {}, put: {}, patch: {} },
        :'/bar/{key}'=> { get: {}, delete: {}, post: {}, put: {}, patch: {}},
      }}
      let(:expected) {[
        { post: {}, put: {}, patch: {}},
        { post: {}, put: {}, patch: {}},
      ]}
      specify { expect { |b| subject.find_post_put(paths, &b) }.to yield_control.twice }
      specify { expect { |b| subject.find_post_put(paths, &b) }.to yield_successive_args *expected }
    end
  end

  describe 'build_definition' do
    let(:verb) { 'post' }
    let(:name) { 'Foo' }
    let(:definitions) {{}}

    specify do
      subject.instance_variable_set(:@definitions, definitions)
      subject.build_definition(verb, name)

      definition = definitions.to_a.first
      expect(definition.first).to eql :postRequestFoo
      expect(definition.last).to eql({ type: 'object', properties: {}, required: [] })
    end
  end

  describe 'move_params_to_new definition' do
    let(:name) { 'Foo' }
    let(:definitions) {{}}

    describe 'post request' do
      let(:verb) { 'post' }
      let(:params) { paths["/in_body"][:post][:parameters] }

      specify do
        subject.instance_variable_set(:@definitions, definitions)
        name = subject.build_definition(verb, name)
        subject.move_params_to_new(verb, name, params)

        expect(definitions[name]).to eql expected_post_defs
        expect(params).to be_empty
      end
    end

    describe 'put request' do
      let(:verb) { 'put' }
      let(:params) { paths["/in_body/{key}"][:put][:parameters] }

      specify do
        subject.instance_variable_set(:@definitions, definitions)
        name, definition = subject.build_definition(verb, name)
        subject.move_params_to_new(verb, name, params)

        expect(definitions[name]).to eql expected_put_defs
        expect(params.length).to be 1
      end
    end
  end

  describe 'find_definition' do
    specify do
      subject.instance_variable_set(:@definitions, definitions)
      subject.find_definition_and_parameters(found_path)

      expect(definitions.keys).to include 'InBody', :postRequestInBody
    end
  end

  describe 'build_body_parameter' do
    let(:response) {{ schema: { '$ref' => '#/definitions/Somewhere'} }}

    describe 'no name given' do
      let(:expected_param) {
        {:name=>"Somewhere", :in=>"body", :required=>true, :schema=>{'$ref' => "#/definitions/Somewhere"}}
      }
      specify do
        parameter = subject.build_body_parameter(response)
        expect(parameter).to eql expected_param
      end
    end

    describe 'name given' do
      let(:name) { 'Foo' }
      let(:expected_param) {
        {:name=>"Somewhere", :in=>"body", :required=>true, :schema=>{'$ref' => "#/definitions/#{name}"}}
      }
      specify do
        parameter = subject.build_body_parameter(response, name)
        expect(parameter).to eql expected_param
      end
    end
  end

  describe 'private methods' do
    describe 'parse_model' do
      let(:ref) { '#/definitions/InBody' }
      subject(:object) { described_class.send(:parse_model, ref) }

      specify { expect(object).to eql 'InBody' }
    end

    describe 'movable' do
      describe 'path' do
        let(:param) {{ in: "path", name: "key", description: nil, type: "integer", format: "int32", required: true }}
        it { expect(subject.send(:movable?, param)).to be true }
      end

      describe 'body' do
        let(:param) {{ in: "body", name: "in_body", description: "in_body", type: "integer", format: "int32", required: true }}
        it { expect(subject.send(:movable?, param)).to be true }
      end

      describe 'query' do
        let(:param) {{ in: "query", name: "in_query", description: "in_query", type: "integer", format: "int32", required: true }}
        it { expect(subject.send(:movable?, param)).to be false }
      end

      describe 'header' do
        let(:param) {{ in: "header", name: "in_header", description: "in_header", type: "integer", format: "int32", required: true }}
        it { expect(subject.send(:movable?, param)).to be false }
      end
    end

    describe 'deletable' do
      describe 'path' do
        let(:param) {{ in: "path", name: "key", description: nil, type: "integer", format: "int32", required: true }}
        it { expect(subject.send(:deletable?, param)).to be false }
      end

      describe 'body' do
        let(:param) {{ in: "body", name: "in_body_1", description: "in_body_1", type: "integer", format: "int32", required: true }}
        it { expect(subject.send(:deletable?, param)).to be true }
      end

      describe 'query' do
        let(:param) {{ in: "query", name: "in_query_1", description: "in_query_1", type: "integer", format: "int32", required: true }}
        it { expect(subject.send(:deletable?, param)).to be false }
      end

      describe 'header' do
        let(:param) {{ in: "header", name: "in_header_1", description: "in_header_1", type: "integer", format: "int32", required: true }}
        it { expect(subject.send(:deletable?, param)).to be false }
      end
    end

    describe 'should move' do
      describe 'no move' do
        let(:params) {[
          { in: "path", name: "key", description: nil, type: "integer", format: "int32", required: true },
          { in: "formData", name: "in_form_data", description: "in_form_data", type: "integer", format: "int32", required: true }
        ]}
        it { expect(subject.send(:should_move?, params)).to be false }
      end

      describe 'move' do
        let(:params) {[
          { in: "path", name: "key", description: nil, type: "integer", format: "int32", required: true },
          { in: "body", name: "in_bosy", description: "in_bosy", type: "integer", format: "int32", required: true },
          { in: "formData", name: "in_form_data", description: "in_form_data", type: "integer", format: "int32", required: true }
        ]}
        it { expect(subject.send(:should_move?, params)).to be true }
      end
    end

    describe 'unify' do
      before do
        subject.send(:unify!, params) if subject.send(:should_move?, params)
      end
      describe 'param type with `:in` given' do
        let(:params) {[
          { in: "path", name: "key", description: nil, type: "integer", format: "int32", required: true },
          { in: "body", name: "in_body", description: "in_body", type: "integer", format: "int32", required: true },
          { in: "query", name: "in_query", description: "in_query", type: "integer", format: "int32", required: true },
          { in: "header", name: "in_header", description: "in_header", type: "integer", format: "int32", required: true },
          { in: "formData", name: "in_form_data", description: "in_form_data", type: "integer", format: "int32", required: true }
        ]}

        let(:expected_params) {[
          { in: "path", name: "key", description: nil, type: "integer", format: "int32", required: true },
          { in: "body", name: "in_body", description: "in_body", type: "integer", format: "int32", required: true },
          { in: "query", name: "in_query", description: "in_query", type: "integer", format: "int32", required: true },
          { in: "header", name: "in_header", description: "in_header", type: "integer", format: "int32", required: true },
          { in: "body", name: "in_form_data", description: "in_form_data", type: "integer", format: "int32", required: true }
        ]}
        it { expect(params).to eql expected_params }
      end

      describe 'let it as is' do
        let(:params) {[
          { in: "path", name: "key", description: nil, type: "integer", format: "int32", required: true },
          { in: "formData", name: "in_form_data", description: "in_form_data", type: "integer", format: "int32", required: true }
        ]}

        let(:expected_params) {[
          { in: "path", name: "key", description: nil, type: "integer", format: "int32", required: true },
          { in: "formData", name: "in_form_data", description: "in_form_data", type: "integer", format: "int32", required: true }
        ]}
        it { expect(params).to eql expected_params }

      end

      describe 'param type with `:param_type` given' do
        let(:params) {[
          { param_type: "path", name: "key", description: nil, type: "integer", format: "int32", required: true },
          { param_type: "body", name: "in_body", description: "in_body", type: "integer", format: "int32", required: true },
          { param_type: "query", name: "in_query", description: "in_query", type: "integer", format: "int32", required: true },
          { param_type: "header", name: "in_header", description: "in_header", type: "integer", format: "int32", required: true },
          { param_type: "formData", name: "in_form_data", description: "in_form_data", type: "integer", format: "int32", required: true }
        ]}

        let(:expected_params) {[
          { name: "key", description: nil, type: "integer", format: "int32", required: true, in: "path" },
          { name: "in_body", description: "in_body", type: "integer", format: "int32", required: true, in: "body" },
          { name: "in_query", description: "in_query", type: "integer", format: "int32", required: true, in: "query" },
          { name: "in_header", description: "in_header", type: "integer", format: "int32", required: true, in: "header" },
          { name: "in_form_data", description: "in_form_data", type: "integer", format: "int32", required: true, in: "body" }
        ]}
        it { expect(params).to eql expected_params }
      end
    end

  end
end
