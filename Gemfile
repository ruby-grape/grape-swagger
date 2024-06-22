# frozen_string_literal: true

source 'http://rubygems.org'

gemspec

gem 'grape', case version = ENV.fetch('GRAPE_VERSION', '< 3.0')
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

  grape_version = ENV.fetch('GRAPE_VERSION', '2.1.0')
  if grape_version == 'HEAD' || Gem::Version.new(grape_version) >= Gem::Version.new('2.0.0')
    gem 'rack', '>= 3.0'
  else
    gem 'rack', '< 3.0'
  end

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
  gem 'simplecov', require: false
end
