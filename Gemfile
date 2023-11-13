# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'grape', case version = ENV.fetch('GRAPE_VERSION', '~> 1.8')
             when 'HEAD'
               { git: 'https://github.com/ruby-grape/grape' }
             else
               version
             end

gem ENV.fetch('MODEL_PARSER', nil) if ENV.key?('MODEL_PARSER')

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
  gem 'rspec', '~> 3.9'
  gem 'rubocop', '~> 1.50', require: false

  unless ENV['MODEL_PARSER'] == 'grape-swagger-entity'
    gem 'grape-swagger-entity', git: 'https://github.com/ruby-grape/grape-swagger-entity'
  end
end

group :test do
  gem 'coveralls_reborn', require: false
  gem 'ruby-grape-danger', '~> 0.2.0', require: false
  gem 'simplecov', require: false
end
