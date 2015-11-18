require "./lib/recaptcha/version"

Gem::Specification.new do |s|
  s.name        = "recaptcha"
  s.version     = Recaptcha::VERSION
  s.authors     = ["Jason L Perry"]
  s.email       = ["jasper@ambethia.com"]
  s.homepage    = "http://github.com/ambethia/recaptcha"
  s.summary     = s.description = "Helpers for the reCAPTCHA API"
  s.license     = "MIT"

  s.files         = `git ls-files lib README.rdoc CHANGELOG LICENSE`.split("\n")

  s.add_development_dependency "mocha"
  s.add_development_dependency "rake"
  s.add_development_dependency "activesupport"
  s.add_development_dependency "i18n"
  s.add_development_dependency "minitest", "~> 5.0"
  s.add_development_dependency "pry-byebug"
end
