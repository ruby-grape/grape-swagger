source 'http://rubygems.org'

gemspec

case version = ENV['GRAPE_VERSION'] || '~> 0.9.0'
when 'HEAD'
  gem 'grape', github: 'ruby-grape/grape'
else
  gem 'grape', version
end

case version = ENV['GRAPE_ENTITY_VERSION'] || '~> 0.4.0'
when 'HEAD'
  gem 'grape-entity', github: 'ruby-grape/grape-entity'
else
  gem 'grape-entity', version
end
