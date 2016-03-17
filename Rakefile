#!/usr/bin/env rake
require 'foodcritic'
require 'rake'
require 'bundler/setup'

desc "Runs knife cookbook test"
task :knife do
  sh "bundle exec knife cookbook test cookbook -o ./ -a"
end

desc "Runs foodcritic test"
task :foodcritic do
  FoodCritic::Rake::LintTask.new
  sh "bundle exec foodcritic -f any ."
end

desc "Runs rubocop checks"
task :rubocop do
  sh "bundle exec rubocop --fail-level warn"
end

desc 'Run integration tests with kitchen-docker'
task :docker, [:instance] do |_t, args|
  args.with_defaults(instance: 'ci-centos-72')
  require 'kitchen'
  Kitchen.logger = Kitchen.default_file_logger
  loader = Kitchen::Loader::YAML.new(local_config: './.kitchen.docker.yml')
  instances = Kitchen::Config.new(loader: loader).instances
  # Travis CI Docker service does not support destroy:
  instances.get(args.instance).verify
end

task :ci => [:foodcritic, :knife, :docker]
task :default => [:foodcritic, :rubocop, :knife, :dist]
