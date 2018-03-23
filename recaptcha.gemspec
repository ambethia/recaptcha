require "./lib/recaptcha/version"

Gem::Specification.new do |s|
  s.name        = "recaptcha"
  s.version     = Recaptcha::VERSION
  s.authors     = ["Jason L Perry"]
  s.email       = ["jasper@ambethia.com"]
  s.homepage    = "http://github.com/ambethia/recaptcha"
  s.summary     = s.description = "Helpers for the reCAPTCHA API"
  s.license     = "MIT"
  s.required_ruby_version = '>= 1.8.7'

  s.files       = `git ls-files lib README.md CHANGELOG.md LICENSE`.split("\n")

  s.add_runtime_dependency "json", "~> 1.8.1"
  s.add_runtime_dependency "rack", "~> 1.4.7"
  s.add_development_dependency "mocha", "~> 1.4.0"
  s.add_development_dependency "rake", "~> 0.8.7"
  s.add_development_dependency "activesupport", "~> 2.3.10"
  s.add_development_dependency "i18n", "~> 0.6.11"
  s.add_development_dependency "minitest", "~> 5.11.3"
  s.add_development_dependency "minitest-hooks", "~> 1.4.2"
  s.add_development_dependency "webmock", "~> 1.24.6"
  s.add_development_dependency "hashdiff", "< 0.3.6"
  s.add_development_dependency "addressable", "< 2.4.0"
end
