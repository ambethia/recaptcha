require "./lib/recaptcha/version"

Gem::Specification.new do |s|
  s.name        = "recaptcha"
  s.version     = Recaptcha::VERSION
  s.authors     = ["Jason L Perry"]
  s.email       = ["jasper@ambethia.com"]
  s.homepage    = "http://github.com/ambethia/recaptcha"
  s.summary     = s.description = "Helpers for the reCAPTCHA API"
  s.license     = "MIT"
  s.required_ruby_version = '>= 1.9.3'

  s.files       = `git ls-files lib README.md CHANGELOG.md LICENSE`.split("\n")

  s.add_runtime_dependency "json"
  s.add_development_dependency "mocha"
  s.add_development_dependency "rake"
  s.add_development_dependency "activesupport"
  s.add_development_dependency "i18n"
  s.add_development_dependency "maxitest"
  s.add_development_dependency "pry-byebug"
  s.add_development_dependency "bump"
  s.add_development_dependency "webmock"
  s.add_development_dependency "rubocop"
end
