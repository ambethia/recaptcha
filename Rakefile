require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'echoe'

Echoe.new('recaptcha', '0.1.0') do |p|
  p.description    = "This plugin adds helpers for the ReCAPTCHA API "
  p.url            = "http://github.com/ambethia/recaptcha/tree/master"
  p.author         = "Jason L. Perry"
  p.email          = "jasper@ambethia.com"
  p.ignore_pattern = ["pkg/**/*"]
  p.development_dependencies = []
end


desc 'Default: run unit tests.'
task :default => :test

desc 'Test the recaptcha plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

ALLISON = "/Library/Ruby/Gems/1.8/gems/allison-2.0.3/lib/allison.rb"  
  
Rake::RDocTask.new do |rd|  
  rd.main = "README.rdoc"  
  rd.rdoc_files.include "README.rdoc", "LICENSE", "lib/**/*.rb"
  rd.title = "ReCAPTCHA"  
  rd.options << '-N' # line numbers  
  rd.options << '-S' # inline source  
  rd.template = ALLISON if File.exist?(ALLISON)  
end

desc "Upload the rdoc to ambethia.com"
task "publish" do
  sh "scp -r html/* ambethia.com:~/www/ambethia.com/recaptcha"
end