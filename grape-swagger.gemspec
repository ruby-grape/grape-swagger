# frozen_string_literal: true

require_relative 'lib/grape-swagger/version'

Gem::Specification.new do |s|
  s.name        = 'grape-swagger'
  s.version     = GrapeSwagger::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['LeFnord', 'Tim Vandecasteele']
  s.email       = ['pscholz.le@gmail.com', 'tim.vandecasteele@gmail.com']
  s.homepage    = 'https://github.com/ruby-grape/grape-swagger'
  s.summary     = 'Add auto generated documentation to your Grape API that can be displayed with Swagger.'
  s.license     = 'MIT'

  s.metadata['rubygems_mfa_required'] = 'true'

  s.required_ruby_version = '>= 3.0'
  s.add_runtime_dependency 'grape', '>= 1.7', '< 3.0'
  s.add_runtime_dependency 'rack-test', '~> 2'

  s.files = Dir['lib/**/*', '*.md', 'LICENSE.txt', 'grape-swagger.gemspec']
  s.require_paths = ['lib']
end
