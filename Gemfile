# frozen_string_literal: true

source 'http://rubygems.org'

ruby RUBY_VERSION

gemspec

gem 'grape', case version = ENV['GRAPE_VERSION'] || '>= 1.5.0'
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

  gem 'rack', '~> 2.2'
  gem 'rack-cors'
  gem 'rack-test'
  gem 'rake'
  gem 'rdoc'
  gem 'rspec', '~> 3.9'
  gem 'rubocop', '~> 1.0', require: false
end

group :test do
  gem 'coveralls_reborn', require: false

  gem 'ruby-grape-danger', '~> 0.2.0', require: false
  gem 'simplecov', require: false

  unless ENV['MODEL_PARSER'] == 'grape-swagger-entity'
    gem 'grape-swagger-entity', git: 'https://github.com/ruby-grape/grape-swagger-entity'
  end
end
