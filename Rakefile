# frozen_string_literal: true

require 'rubygems'
require 'bundler'

Bundler.setup(:default, :development)

require 'rake'

Bundler::GemHelper.install_tasks

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

task default: %i[spec rubocop]
