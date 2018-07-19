# frozen_string_literal: true

source 'http://rubygems.org'

ruby RUBY_VERSION

gemspec

gem 'grape', case version = ENV['GRAPE_VERSION'] || '~> 1.0'
             when 'HEAD'
               { git: 'https://github.com/ruby-grape/grape' }
             else
               version
             end

gem ENV['MODEL_PARSER'] if ENV.key?('MODEL_PARSER')

group :development, :test do
  gem 'bundler'
  gem 'grape-entity'
  gem 'pry', platforms: [:mri]
  gem 'pry-byebug', platforms: [:mri]
  gem 'rack'
  gem 'rack-cors'
  gem 'rack-test'
  gem 'rake'
  gem 'rdoc'
  gem 'rspec', '~> 3.0'
  gem 'rubocop', '~> 0.58', require: false
end

group :test do
  gem 'coveralls', '~> 0.8', require: false
  gem 'grape-swagger-entity'
  gem 'ruby-grape-danger', '~> 0.1.1', require: false
  gem 'simplecov', require: false
end
