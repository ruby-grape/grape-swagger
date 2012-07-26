# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "grape-swagger"
  gem.homepage = "http://github.com/tim-vandecasteele/grape-swagger"
  gem.license = "MIT"
  gem.summary = %Q{Add swagger compliant documentation to your grape API}
  gem.description = %Q{A simple way to add proper auto generated documentation - that can be displayed with swagger - to your inline described grape API}
  gem.email = "tim.vandecasteele@gmail.com"
  gem.authors = ["Tim Vandecasteele"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new



Bundler::GemHelper.install_tasks

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
