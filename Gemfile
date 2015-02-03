source 'http://rubygems.org'

gemspec

case version = ENV['GRAPE_VERSION'] || '~> 0.10.1'
when 'HEAD'
  gem 'grape', github: 'intridea/grape'
else
  gem 'grape', version
end
