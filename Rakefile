# frozen_string_literal: true

require 'rubygems'
require 'bundler'

Bundler.setup(:default, :development)

require 'rake'

Bundler::GemHelper.install_tasks

# Disable Bundler's local release tasks so the Release workflow is the only release path.
# `clear` also drops their prerequisites, so nothing is built or tagged before the abort.
%w[release release:rubygem_push release:source_control_push].each do |name|
  Rake::Task[name].clear if Rake::Task.task_defined?(name)
  task(name) { abort "#{name} is disabled; dispatch the Release workflow instead: gh workflow run release.yml" }
end

if Gem.loaded_specs.key?('ruby-gem-release')
  require 'ruby-gem-release/workflow/ruby_gem'
  require 'ruby-gem-release/changelog'

  RubyGemRelease::Workflow::RubyGem.new(
    version: RubyGemRelease::Version::RubyConstant.new(path: 'lib/grape-swagger/version.rb', constant: 'VERSION'),
    changelog: RubyGemRelease::Changelog::Intridea.new(
      path: 'CHANGELOG.md', placeholder: '* Your contribution here.', date_format: '%Y-%m-%d',
      sections: %w[Features Fixes]
    )
  ).install_tasks
end

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

task default: %i[spec rubocop]
