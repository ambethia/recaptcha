# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"
require "bump/tasks"

task default: [:test, :rubocop]

Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
end

desc "rubocop"
task :rubocop do
  sh "rubocop"
end

task default: [:test, :rubocop]
