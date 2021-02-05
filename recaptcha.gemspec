# frozen_string_literal: true

require "./lib/recaptcha/version"

Gem::Specification.new do |s|
  s.name        = "recaptcha"
  s.version     = Recaptcha::VERSION
  s.authors     = ["Jason L Perry"]
  s.email       = ["jasper@ambethia.com"]
  s.homepage    = "http://github.com/ambethia/recaptcha"
  s.summary     = s.description = "Helpers for the reCAPTCHA API"
  s.license     = "MIT"
  s.required_ruby_version = '>= 2.4.0'

  s.files       = `git ls-files lib rails README.md CHANGELOG.md LICENSE`.split("\n")

  s.add_runtime_dependency "json"
  s.add_development_dependency "mocha"
  s.add_development_dependency "rake"
  s.add_development_dependency "i18n"
  s.add_development_dependency "maxitest"
  s.add_development_dependency "pry-byebug"
  s.add_development_dependency "bump"
  s.add_development_dependency "webmock"
  s.add_development_dependency "rubocop"

  s.metadata = { "source_code_uri" => "https://github.com/ambethia/recaptcha" }
end
