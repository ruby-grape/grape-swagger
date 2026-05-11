# frozen_string_literal: true

describe GrapeSwagger::RequestParamParsers::Route do
  let(:route) { instance_double('route', app: nil) }

  describe '#parse' do
    subject(:parse_request_params) { described_class.parse(route, nil, nil, nil) }

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

    context 'when route.params fails due missing named_captures support' do
      before do
        allow(route).to receive(:params).and_raise(
          NoMethodError,
          "undefined method `named_captures' for an instance of Mustermann::Grape"
        )
        allow(route).to receive(:pattern_regexp).and_return(%r{\A/(?<id>[^/]+)\z})
        allow(route).to receive(:options).and_return(params: { 'name' => { required: false, type: 'String' } })
      end

      it 'falls back to pattern captures and route options params' do
        expect(parse_request_params).to eq(
          id: { required: true, type: 'Integer' },
          name: { required: false, type: 'String' }
        )
      end
    end
  end
end
