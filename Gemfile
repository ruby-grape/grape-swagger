source 'http://rubygems.org'

ruby RUBY_VERSION

gemspec

gem 'grape', case version = ENV['GRAPE_VERSION'] || '~> 0.18'
             when 'HEAD'
               { github: 'ruby-grape/grape' }
             else
               version
             end

gem ENV['MODEL_PARSER'] if ENV.key?('MODEL_PARSER')

group :development, :test do
  gem 'bundler'
  gem 'kramdown'
  gem 'pry', platforms: [:mri]
  gem 'pry-byebug', platforms: [:mri]
  gem 'rack'
  gem 'rack-cors'
  gem 'rack-test'
  gem 'rake'
  gem 'rdoc'
  gem 'redcarpet', platforms: [:mri]
  gem 'rouge', platforms: [:mri]
  gem 'rspec', '~> 3.0'
  gem 'rubocop', '~> 0.40'
  gem 'shoulda'
end
group :test do
  gem 'grape-entity'
  gem 'grape-swagger-entity'
  gem 'ruby-grape-danger', '~> 0.1.0', require: false
end
