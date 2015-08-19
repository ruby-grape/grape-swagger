$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'grape-swagger/version'

Gem::Specification.new do |s|
  s.name        = 'grape-swagger'
  s.version     = GrapeSwagger::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Tim Vandecasteele']
  s.email       = ['tim.vandecasteele@gmail.com']
  s.homepage    = 'https://github.com/ruby-grape/grape-swagger'
  s.summary     = 'A simple way to add auto generated documentation to your Grape API that can be displayed with Swagger.'
  s.license     = 'MIT'

  s.add_runtime_dependency 'grape', '>= 0.8.0'
  s.add_runtime_dependency 'grape-entity'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rack-cors'
  s.add_development_dependency 'rubocop', '0.33.0'
  s.add_development_dependency 'kramdown', '~> 1.4.1'
  s.add_development_dependency 'redcarpet', '~> 3.1.2' unless RUBY_PLATFORM.eql? 'java'
  s.add_development_dependency 'rouge', '~> 1.6.1'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec}/*`.split("\n")
  s.require_paths = ['lib']
end
