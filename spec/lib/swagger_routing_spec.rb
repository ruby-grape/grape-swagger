# frozen_string_literal: true

describe GrapeSwagger::SwaggerRouting do
  let(:routing) do
    Class.new do
      include GrapeSwagger::SwaggerRouting
    end.new
  end

  describe '#combine_routes' do
    let(:app) { instance_double('app', routes: routes) }

    context 'when route.prefix contains regexp metacharacters' do
      let(:route) { instance_double('route', path: '/v1+0/widgets', prefix: 'v1+0') }
      let(:routes) { [route] }
      let(:doc_klass) { instance_double('doc_klass', hide_documentation_path: false) }

      it 'matches the literal prefix when extracting the resource name' do
        expect(routing.send(:combine_routes, app, doc_klass)).to eq('widgets' => [route])
      end
    end

    context 'when mount_path contains regexp metacharacters' do
      let(:route) { instance_double('route', path: '/swagger.doc+v1', prefix: nil) }
      let(:routes) { [route] }
      let(:doc_klass) { instance_double('doc_klass', hide_documentation_path: true, mount_path: '/swagger.doc+v1') }

      it 'hides the literal documentation route' do
        expect(routing.send(:combine_routes, app, doc_klass)).to eq('swagger' => [])
      end
    end
  end
end
