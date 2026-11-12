# frozen_string_literal: true

require 'rubygems'
require 'bundler'

Bundler.setup(:default, :development)

require 'rake'

Bundler::GemHelper.install_tasks

# Publish only through the Release workflow, never a local push to rubygems.org.
Rake::Task['release'].clear
desc 'Publish through the Release workflow'
task :release do
  abort 'Dispatch the Release workflow instead: gh workflow run release.yml'
end

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3.0')
  require 'ruby-gem-release/workflow/ruby_gem'
  require 'ruby-gem-release/changelog'

  RubyGemRelease::Workflow::RubyGem.new(
    version: RubyGemRelease::Version::RubyConstant.new(path: 'lib/grape-swagger/version.rb', constant: 'VERSION'),
    changelog: RubyGemRelease::Changelog::Intridea.new(path: 'CHANGELOG.md', placeholder: '* Your contribution here.')
  ).install_tasks
end

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

task default: %i[spec rubocop]
