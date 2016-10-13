source 'http://rubygems.org'

gemspec

case version = ENV['GRAPE_VERSION'] || '~> 0.18'
when 'HEAD'
  gem 'grape', github: 'ruby-grape/grape'
else
  gem 'grape', version
end

gem ENV['MODEL_PARSER'] if ENV.key?('MODEL_PARSER')

if RUBY_VERSION < '2.2.2'
  gem 'rack', '<2.0.0'
  gem 'activesupport', '<5.0.0'
end

group :test do
  gem 'ruby-grape-danger', '~> 0.1.0', require: false
  gem 'grape-entity'
  gem 'grape-swagger-entity'
end
