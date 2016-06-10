require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"
require "bump/tasks"

Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
end

desc "rubocop"
task :rubocop do
  sh "rubocop --display-cop-names"
end

task default: [:test, :rubocop]
