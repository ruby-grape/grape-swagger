# -*- encoding: utf-8 -*-
require File.expand_path('../lib/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Tim Vandecasteele"]
  gem.email         = ["tim.vandecasteele@gmail.com"]
  gem.description   = "A simple way to add proper auto generated documentation - that can be displayed with swagger - to your inline described grape API"
  gem.homepage      = "http://github.com/tim-vandecasteele/grape-swagger"
  gem.summary       = gem.description
  gem.license       = 'MIT'

  gem.name          = "grape-swagger"
  gem.require_paths = ["lib"]
  gem.files         = `git ls-files`.split("\n")
  gem.version       = GrapeSwagger::VERSION

  gem.add_dependency "grape"
  gem.add_dependency "grape-entity"
  gem.add_dependency "kramdown"

  gem.add_development_dependency "shoulda"
  gem.add_development_dependency "rdoc"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "rack-test"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rake"
end