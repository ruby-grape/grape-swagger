# frozen_string_literal: true

describe GrapeSwagger::RequestParamParsers::Route do
  let(:route) { instance_double('route', app: nil) }

  describe '#parse' do
    subject(:parse_request_params) { described_class.parse(route, nil, nil, nil) }

    context 'when inherited namespace stackable values contain path params across levels' do
      let(:root_stackable) { Grape::Util::StackableValues.new }
      let(:nested_stackable) { Grape::Util::StackableValues.new(root_stackable) }
      let(:inheritable_setting) { instance_double('inheritable_setting', namespace_stackable: nested_stackable) }
      let(:app) { instance_double('app', inheritable_setting: inheritable_setting) }

      before do
        root_stackable[:namespace] = instance_double('namespace', space: ':account_id', options: { required: true, type: 'Integer' })
        nested_stackable[:namespace] = instance_double('namespace', space: ':id', options: { required: true, type: 'String' })

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
  end
end
