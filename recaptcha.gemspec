# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{recaptcha}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jason L. Perry"]
  s.date = %q{2009-02-08}
  s.description = %q{This plugin adds helpers for the ReCAPTCHA API}
  s.email = %q{jasper@ambethia.com}
  s.extra_rdoc_files = ["CHANGELOG", "lib/recaptcha/recaptcha.rb", "lib/recaptcha.rb", "LICENSE", "README.rdoc", "tasks/recaptcha_tasks.rake"]
  s.files = ["CHANGELOG", "init.rb", "lib/recaptcha/recaptcha.rb", "lib/recaptcha.rb", "LICENSE", "Manifest", "Rakefile", "README.rdoc", "tasks/recaptcha_tasks.rake", "test/recaptcha_test.rb", "test/verify_recaptcha_test.rb", "recaptcha.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/ambethia/recaptcha/tree/master}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Recaptcha", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{recaptcha}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{This plugin adds helpers for the ReCAPTCHA API}
  s.test_files = ["test/recaptcha_test.rb", "test/verify_recaptcha_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
