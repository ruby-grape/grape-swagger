# frozen_string_literal: true
source 'http://rubygems.org'

ruby RUBY_VERSION

gemspec

gem 'grape', case version = ENV['GRAPE_VERSION'] || '~> 0.19'
             when 'HEAD'
               { github: 'ruby-grape/grape' }
             else
               version
             end

gem ENV['MODEL_PARSER'] if ENV.key?('MODEL_PARSER')

group :development, :test do
  gem 'bundler'
  gem 'pry', platforms: [:mri]
  gem 'pry-byebug', platforms: [:mri]
  gem 'rack'
  gem 'rack-cors'
  gem 'rack-test'
  gem 'rake'
  gem 'rdoc'
  gem 'rspec', '~> 3.0'
  gem 'rubocop', '~> 0.46'
end
group :test do
  gem 'coveralls', require: false
  gem 'grape-entity'
  gem 'grape-swagger-entity'
  gem 'ruby-grape-danger', '~> 0.1.1', require: false
  gem 'simplecov', require: false
end
