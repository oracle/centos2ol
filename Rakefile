#!/usr/bin/env rake
# frozen_string_literal: true

require 'pronto'

namespace :style do
  begin
    Pronto::GemNames.new.to_a.each { |gem_name| require "pronto/#{gem_name}" }

    desc 'Run shell style checks'
    task :shell do
      Pronto.run(`git log --pretty=format:%H | tail -1`)
    end
  rescue LoadError => e
    puts ">>> Gem load error: #{e}, omitting style:shell"
  end

  begin
    require 'rubocop/rake_task'

    desc 'Run Ruby style checks'
    RuboCop::RakeTask.new(:ruby) do |task|
      task.options << '--display-cop-names'
    end
  rescue LoadError => e
    puts ">>> Gem load error: #{e}, omitting style:ruby" unless ENV['CI']
  end
end

desc 'Run all style checks'
task style: ['style:shell', 'style:ruby']

# Integration tests. Kitchen.ci
begin
  require 'kitchen/cli'

  concurrency = 3

  namespace :integration do
    task :set_vagrant, [:regex] do |_t, _args|
      ENV['KITCHEN_LOCAL_YAML'] = './.kitchen.yml'
    end

    desc 'Run Test Kitchen with Vagrant'
    task :vagrant, [:regex] => :set_vagrant do |_t, args|
      Kitchen::CLI.new([], concurrency: concurrency, destroy: 'always').test args[:regex]
    end

    namespace :vagrant do
      desc 'Lists one or more vagrant instances'
      task :list, [:regex] => :set_vagrant do |_t, args|
        Kitchen::CLI.new([], concurrency: concurrency).list args[:regex]
      end

      desc 'Log in to one vagrant instance'
      task :login, [:regex] => :set_vagrant do |_t, args|
        Kitchen::CLI.new([]).login args[:regex]
      end

      desc 'Start one or more vagrant instances'
      task :create, [:regex] => :set_vagrant do |_t, args|
        Kitchen::CLI.new([], concurrency: concurrency).create args[:regex]
      end

      desc 'Use a provisioner to configure one or more vagrant instances'
      task :converge, [:regex] => :set_vagrant do |_t, args|
        Kitchen::CLI.new([], concurrency: concurrency).converge args[:regex]
      end

      desc 'Install busser and related gems on one or more vagrant instances'
      task :setup, [:regex] => :set_vagrant do |_t, args|
        Kitchen::CLI.new([], concurrency: concurrency).setup args[:regex]
      end

      desc 'Run automated tests on one or more vagrant instances'
      task :verify, [:regex] => :set_vagrant do |_t, args|
        Kitchen::CLI.new([], concurrency: concurrency).verify args[:regex]
      end

      desc 'Delete all information for one or more vagrant instances'
      task :destroy, [:regex] => :set_vagrant do |_t, args|
        Kitchen::CLI.new([]).destroy args[:regex]
      end

      desc 'Test (destroy, create, converge, setup, verify and destroy) one or more vagrant instances'
      task :test, [:regex] => :set_vagrant do |_t, args|
        Kitchen::CLI.new([], concurrency: concurrency, destroy: 'always').test args[:regex]
      end
    end
  end
rescue LoadError => e
  puts ">>> Gem load error: #{e}, omitting spec" unless ENV['CI']
end

task default: %w[style integration:vagrant]
