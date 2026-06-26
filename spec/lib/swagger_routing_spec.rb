# frozen_string_literal: true

describe GrapeSwagger::SwaggerRouting do
  let(:routing) do
    Class.new do
      include GrapeSwagger::SwaggerRouting
    end.new
  end
  let(:namespace) { instance_double('namespace', options: {}) }

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

    context 'when route.prefix is nil' do
      let(:route) { instance_double('route', path: '/widgets', prefix: nil) }
      let(:routes) { [route] }
      let(:doc_klass) { instance_double('doc_klass', hide_documentation_path: false) }

      it 'treats the prefix as an empty string when extracting the resource name' do
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

    context 'when joined mount paths contain multiple double-slash runs' do
      it 'normalizes all doubled slashes in the namespace key' do
        namespace_stackable = Grape::Util::StackableValues.new
        namespace_stackable[:namespace] = namespace
        namespace_stackable[:mount_path] = ['//foo/', '/bar']
        endpoint = instance_double(
          'endpoint',
          options: {},
          namespace: '/bar/widgets',
          inheritable_setting: instance_double('inheritable_setting', namespace_stackable: namespace_stackable)
        )
        app = Class.new
        app.extend(GrapeSwagger::SwaggerDocumentationAdder)

        allow(app).to receive(:endpoints).and_return([endpoint])

        expect(app.send(:combine_namespaces, app)).to eq('foo/bar/bar/widgets' => namespace)
      end
    end
  end

  describe '#route_path_start_with?' do
    context 'when route.prefix is an empty string' do
      let(:route) { instance_double('route', prefix: '', path: '/widgets/details') }

      it 'treats the route as unprefixed' do
        expect(routing.send(:route_path_start_with?, route, 'widgets')).to be(true)
      end
    end
  end

  describe '#combine_namespace_routes' do
    let(:user_namespace) { instance_double('namespace', options: { swagger: { nested: false } }) }
    let(:users_namespace) { instance_double('namespace', options: { swagger: { nested: true } }) }

    it 'does not treat sibling namespaces with common prefixes as parent-child' do
      namespaces = {
        'user' => user_namespace,
        'users' => users_namespace
      }
      user_route = instance_double('route')
      users_route = instance_double('route')
      routes = {
        'user' => [user_route],
        'users' => [users_route]
      }

      allow(routing).to receive(:determine_namespaced_routes) do |name, _, _|
        routes.fetch(name)
      end

      expect(routing.send(:combine_namespace_routes, namespaces, routes)).to eq(
        'users' => [users_route]
      )
    end
  end
end
