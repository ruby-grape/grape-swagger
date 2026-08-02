# frozen_string_literal: true

describe GrapeSwagger::RequestParamParsers::Route do
  # Grape::Util::StackableValues's constructor signature is a Grape-internal
  # detail that differs across supported Grape versions (and grape=HEAD), so
  # rather than calling `.new` directly, these specs harvest a real instance
  # through the public API and stub its readers for the scenario under test.
  # `instance_double` won't pass `route.rb`'s `is_a?(Grape::Util::StackableValues)`
  # check, hence harvesting a real instance instead of building a plain double.
  # `#[]` reads Grape's own ivars, not the stubbed readers below, so it is
  # stubbed too -- otherwise it would silently return the harvest probe's real
  # (empty) namespace instead of the fixture if a caller ever read through `[]`.
  def stackable_values_double(new_values, inherited_values = {})
    harvested = Class.new(Grape::API) do
      namespace(':harvest') { get('/probe') { 'probe' } }
    end.routes.first.app.inheritable_setting.namespace_stackable

    allow(harvested).to receive_messages(new_values: new_values, inherited_values: inherited_values)
    allow(harvested).to receive(:[]) { |key| new_values[key] || inherited_values[key] }
    harvested
  end

  let(:route) { instance_double('route', app: nil) }
  let(:parser) { described_class.new(route, nil, nil, nil) }

  describe '#parse' do
    subject(:parse_request_params) { described_class.parse(route, nil, nil, nil) }

    context 'when inherited namespace stackable values contain path params across levels' do
      let(:root_stackable) do
        stackable_values_double(namespace: [instance_double('namespace', space: ':account_id', options: { required: true, type: 'Integer' })])
      end
      let(:nested_stackable) do
        stackable_values_double({ namespace: [instance_double('namespace', space: ':id', options: { required: true, type: 'String' })] }, root_stackable)
      end
      let(:inheritable_setting) { instance_double('inheritable_setting', namespace_stackable: nested_stackable) }
      let(:app) { instance_double('app', inheritable_setting: inheritable_setting) }

      before do
        allow(route).to receive(:app).and_return(app)
        allow(route).to receive(:params).and_return(
          'account_id' => {},
          'id' => {}
        )
      end

      it 'merges path params from the full inherited stackable chain' do
        expect(parse_request_params).to eq(
          account_id: { required: true, type: 'Integer' },
          id: { required: true, type: 'String' }
        )
      end
    end

    context 'when route params include both path-derived and explicitly defined keys' do
      before do
        allow(route).to receive(:params).and_return(
          'id' => {},
          id: { required: true, type: 'String' },
          name: { required: false, type: 'String' }
        )
      end

      it 'keeps explicitly defined params over inferred string path params' do
        expect(parse_request_params).to eq(
          id: { required: true, type: 'String' },
          name: { required: false, type: 'String' }
        )
      end
    end

    context 'when route.params contains only symbol-keyed params' do
      let(:stackable) do
        stackable_values_double(namespace: [instance_double('namespace', space: ':id', options: { required: true, type: 'Integer' })])
      end
      let(:inheritable_setting) { instance_double('inheritable_setting', namespace_stackable: stackable) }
      let(:app) { instance_double('app', inheritable_setting:) }

      before do
        allow(route).to receive(:app).and_return(app)
        allow(route).to receive(:params).and_return(id: {})
      end

      it 'merges namespace options into the symbol-keyed route param' do
        expect(parse_request_params).to eq(
          id: { required: true, type: 'Integer' }
        )
      end
    end

    context 'when namespace space is a colon-prefixed string for a symbol-keyed param' do
      let(:stackable) do
        stackable_values_double(namespace: [instance_double('namespace', space: ':account_id', options: { required: true, type: 'Integer' })])
      end
      let(:inheritable_setting) { instance_double('inheritable_setting', namespace_stackable: stackable) }
      let(:app) { instance_double('app', inheritable_setting:) }

      before do
        allow(route).to receive(:app).and_return(app)
        allow(route).to receive(:params).and_return(account_id: {})
      end

      it 'resolves the namespace space to the matching symbol key' do
        expect(parse_request_params).to eq(
          account_id: { required: true, type: 'Integer' }
        )
      end
    end

    context 'when namespace space has more than one leading colon' do
      let(:stackable) do
        stackable_values_double(namespace: [instance_double('namespace', space: '::id', options: { required: true, type: 'Integer' })])
      end
      let(:inheritable_setting) { instance_double('inheritable_setting', namespace_stackable: stackable) }
      let(:app) { instance_double('app', inheritable_setting:) }

      before do
        allow(route).to receive(:app).and_return(app)
        allow(route).to receive(:params).and_return(':id' => {})
      end

      it 'strips only one leading colon from the namespace space' do
        expect(parse_request_params).to eq(
          ':id': { required: true, type: 'Integer' }
        )
      end
    end

    context 'when inherited namespace stackable values redefine the same path param' do
      let(:root_stackable) do
        stackable_values_double(namespace: [instance_double('namespace', space: ':id', options: { required: true, type: 'Integer' })])
      end
      let(:nested_stackable) do
        stackable_values_double({ namespace: [instance_double('namespace', space: ':id', options: { required: true, type: 'String' })] }, root_stackable)
      end
      let(:inheritable_setting) { instance_double('inheritable_setting', namespace_stackable: nested_stackable) }
      let(:app) { instance_double('app', inheritable_setting:) }

      before do
        allow(route).to receive(:app).and_return(app)
        allow(route).to receive(:params).and_return(
          'id' => {}
        )
      end

      it 'keeps the innermost namespace options for the path param' do
        expect(parse_request_params).to eq(
          id: { required: true, type: 'String' }
        )
      end
    end

    context 'when inherited namespace stackable values partially override the same path param' do
      let(:root_stackable) do
        stackable_values_double(
          namespace: [instance_double(
            'namespace',
            space: ':id',
            options: { documentation: { type: 'integer', format: 'int64' } }
          )]
        )
      end
      let(:nested_stackable) do
        stackable_values_double(
          { namespace: [instance_double(
            'namespace',
            space: ':id',
            options: { desc: 'inner description' }
          )] }, root_stackable
        )
      end
      let(:inheritable_setting) { instance_double('inheritable_setting', namespace_stackable: nested_stackable) }
      let(:app) { instance_double('app', inheritable_setting:) }

      before do
        allow(route).to receive(:app).and_return(app)
        allow(route).to receive(:params).and_return(
          'id' => {}
        )
      end

      it 'preserves outer metadata while applying inner overrides' do
        expect(parse_request_params).to eq(
          id: {
            documentation: { type: 'integer', format: 'int64' },
            desc: 'inner description'
          }
        )
      end
    end

    context 'when inherited namespace stackable values partially override nested documentation' do
      let(:root_stackable) do
        stackable_values_double(
          namespace: [instance_double(
            'namespace',
            space: ':id',
            options: { documentation: { type: 'integer', format: 'int64' } }
          )]
        )
      end
      let(:nested_stackable) do
        stackable_values_double(
          { namespace: [instance_double(
            'namespace',
            space: ':id',
            options: { documentation: { desc: 'inner description' } }
          )] }, root_stackable
        )
      end
      let(:inheritable_setting) { instance_double('inheritable_setting', namespace_stackable: nested_stackable) }
      let(:app) { instance_double('app', inheritable_setting:) }

      before do
        allow(route).to receive(:app).and_return(app)
        allow(route).to receive(:params).and_return(
          'id' => {}
        )
      end

      it 'deep merges nested documentation hashes' do
        expect(parse_request_params).to eq(
          id: {
            documentation: { type: 'integer', format: 'int64', desc: 'inner description' }
          }
        )
      end
    end

    context 'when inherited namespace stackable values partially override deeply nested hashes' do
      let(:root_stackable) do
        stackable_values_double(
          namespace: [instance_double(
            'namespace',
            space: ':id',
            options: { documentation: { schema: { type: 'integer', format: 'int64' } } }
          )]
        )
      end
      let(:nested_stackable) do
        stackable_values_double(
          { namespace: [instance_double(
            'namespace',
            space: ':id',
            options: { documentation: { schema: { desc: 'inner description' } } }
          )] }, root_stackable
        )
      end
      let(:inheritable_setting) { instance_double('inheritable_setting', namespace_stackable: nested_stackable) }
      let(:app) { instance_double('app', inheritable_setting:) }

      before do
        allow(route).to receive(:app).and_return(app)
        allow(route).to receive(:params).and_return(
          'id' => {}
        )
      end

      it 'deep merges beyond one nested hash level' do
        expect(parse_request_params).to eq(
          id: {
            documentation: { schema: { type: 'integer', format: 'int64', desc: 'inner description' } }
          }
        )
      end
    end

    context 'when inherited namespace stackable values override array options' do
      let(:root_stackable) do
        stackable_values_double(
          namespace: [instance_double(
            'namespace',
            space: ':id',
            options: { documentation: { values: %w[outer-a outer-b] } }
          )]
        )
      end
      let(:nested_stackable) do
        stackable_values_double(
          { namespace: [instance_double(
            'namespace',
            space: ':id',
            options: { documentation: { values: %w[inner-a inner-b] } }
          )] }, root_stackable
        )
      end
      let(:inheritable_setting) { instance_double('inheritable_setting', namespace_stackable: nested_stackable) }
      let(:app) { instance_double('app', inheritable_setting:) }

      before do
        allow(route).to receive(:app).and_return(app)
        allow(route).to receive(:params).and_return(
          'id' => {}
        )
      end

      it 'replaces outer arrays with inner arrays' do
        expect(parse_request_params).to eq(
          id: {
            documentation: { values: %w[inner-a inner-b] }
          }
        )
      end
    end
  end

  describe '#fulfill_params' do
    subject(:fulfilled_params) { parser.send(:fulfill_params, path_params, {}) }

    context 'when route.params and path params use symbol keys' do
      let(:path_params) { { id: { required: true, type: 'Integer', format: 'int64' } } }

      before do
        allow(route).to receive(:params).and_return(
          id: {}
        )
      end

      it 'uses normalized symbol keys for path options' do
        expect(fulfilled_params).to eq(
          id: { required: true, type: 'Integer', format: 'int64' }
        )
      end
    end
  end
end
