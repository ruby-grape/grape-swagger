source 'http://rubygems.org'

gemspec

case version = ENV['GRAPE_VERSION'] || '~> 0.16.2'
when 'HEAD'
  gem 'grape', github: 'ruby-grape/grape'
else
  gem 'grape', version
end
